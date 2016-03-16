/*
 * Copyright (C) 2011 Merrimack Valley Library Consortium
 * Jason Stephenson <jstephenson@mvlc.org>
 * Thomas Berezansky <tsbere@mvlc.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

-- If you get a message about needing to drop the function before
-- creating it anew, then you will need to uncomment the following
-- block of code.  This is necessary because the function's return
-- type was changed.
-- DROP FUNCTION IF EXISTS config.create_circ_matrix_matchpoint(
--     org                  TEXT,
--     grp                  TEXT,
--     active               BOOL,
--     circ_modifier        TEXT,
--     marc_type            TEXT,
--     marc_form            TEXT,
--     marc_bib_level       TEXT,
--     marc_vr_format       TEXT,
--     copy_circ_lib        TEXT,
--     copy_owning_lib      TEXT,
--     user_home_ou         TEXT,
--     ref_flag             BOOL,
--     juvenile_flag        BOOL,
--     is_renewal           BOOL,
--     usr_age_lower_bound  INTERVAL,
--     usr_age_upper_bound  INTERVAL,
--     circulate            BOOL,
--     duration_rule        TEXT,
--     recurring_fine_rule  TEXT,
--     max_fine_rule        TEXT,
--     hard_due_date        TEXT,
--     renewals             INT,
--     grace_period         INTERVAL,
--     script_test          TEXT,
--     total_copy_hold_ratio     FLOAT,
--     available_copy_hold_ratio FLOAT,
--     item_age             INTERVAL,
--     copy_location        TEXT);

-- A helper function to be used to create matchpoints.
CREATE OR REPLACE FUNCTION config.create_circ_matrix_matchpoint(
    org                  TEXT,
    grp                  TEXT,
    active               BOOL = TRUE,
    circ_modifier        TEXT = NULL,
    marc_type            TEXT = NULL,
    marc_form            TEXT = NULL,
    marc_bib_level       TEXT = NULL,
    marc_vr_format       TEXT = NULL,
    copy_circ_lib        TEXT = NULL,
    copy_owning_lib      TEXT = NULL,
    user_home_ou         TEXT = NULL,
    ref_flag             BOOL = NULL,
    juvenile_flag        BOOL = NULL,
    is_renewal           BOOL = NULL,
    usr_age_lower_bound  INTERVAL = NULL,
    usr_age_upper_bound  INTERVAL = NULL,
    circulate            BOOL = NULL,
    duration_rule        TEXT = NULL,
    recurring_fine_rule  TEXT = NULL,
    max_fine_rule        TEXT = NULL,
    hard_due_date        TEXT = NULL,
    renewals             INT = NULL,
    grace_period         INTERVAL = NULL,
    script_test          TEXT = NULL,
    total_copy_hold_ratio     FLOAT = NULL,
    available_copy_hold_ratio FLOAT = NULL,
    item_age             INTERVAL = NULL,
    copy_location        TEXT = NULL)
RETURNS INT AS $$
DECLARE
        org_unit_id INT;
        grp_id INT;
        duration_rule_id INT = NULL;
        recurring_fine_rule_id INT = NULL;
        max_fine_rule_id INT = NULL;
        hard_due_date_id INT = NULL;
        copy_circ_lib_id INT = NULL;
        copy_owning_lib_id INT = NULL;
        user_home_ou_id INT = NULL;
        copy_location_id INT = NULL;
        ccmm_id INT = NULL;
BEGIN
        -- If we get a bad shortname and this query returns NULL, then
        -- we get an error on the final insert statement.
        SELECT INTO org_unit_id id
        FROM actor.org_unit
        WHERE shortname = org;

        -- If we get a bad permission group name and this query
        -- returns NULL, then we get an error on the final insert
        -- statement.
        SELECT INTO grp_id id
        FROM permission.grp_tree
        WHERE name = grp;

        IF duration_rule IS NOT NULL THEN
           SELECT INTO duration_rule_id id
           FROM config.rule_circ_duration 
           WHERE name = duration_rule;

           IF duration_rule_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent circ duration rule -> %', duration_rule
                USING HINT = 'Please check your duration_rule';
           END IF;
        END IF;

        IF recurring_fine_rule IS NOT NULL THEN
           SELECT INTO recurring_fine_rule_id id
           FROM config.rule_recurring_fine
           WHERE name = recurring_fine_rule;

           IF recurring_fine_rule_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent recurring fine rule -> %', recurring_fine_rule
                USING HINT = 'Please check your recurring_fine_rule';
           END IF;
        END IF;

        IF max_fine_rule IS NOT NULL THEN
           SELECT INTO max_fine_rule_id id
           FROM config.rule_max_fine
           WHERE name = max_fine_rule;

           IF max_fine_rule_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent max fine rule -> %', max_fine_rule
                USING HINT = 'Please check your max_fine_rule';
           END IF;
        END IF;

        IF hard_due_date IS NOT NULL THEN
           SELECT INTO hard_due_date_id id
           FROM config.hard_due_date
           WHERE name = hard_due_date;

           IF hard_due_date_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent hard due date -> %', hard_due_date
                USING HINT = 'Please check your hard_due_date';
           END IF;
        END IF;

        IF copy_circ_lib IS NOT NULL THEN
           SELECT INTO copy_circ_lib_id id
           FROM actor.org_unit
           WHERE shortname = copy_circ_lib;

           IF copy_circ_lib_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent location -> %', copy_circ_lib
                USING HINT = 'Please check your copy_circ_lib';
           END IF;
        END IF;

        IF copy_owning_lib IS NOT NULL THEN
           SELECT INTO copy_owning_lib_id id
           FROM actor.org_unit
           WHERE shortname = copy_owning_lib;

           IF copy_owning_lib_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent location -> %', copy_owning_lib
                USING HINT = 'Please check your copy_owning_lib';
           END IF;
        END IF;

        IF user_home_ou IS NOT NULL THEN
           SELECT INTO user_home_ou_id id
           FROM actor.org_unit
           WHERE shortname = user_home_ou;

           IF user_home_ou_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent location -> %', user_home_ou
                USING HINT = 'Please check your user_home_ou';
           END IF;
        END IF;

        IF copy_location IS NOT NULL THEN
           SELECT INTO copy_location_id acl.id
           FROM asset.copy_location acl
           JOIN actor.org_unit_ancestors_distance(org_unit_id) AS ad
           ON acl.owning_lib = ad.id
           WHERE acl.name = copy_location
           ORDER BY ad.distance
           LIMIT 1;

           IF copy_location_id IS NULL THEN
            RAISE EXCEPTION 'Nonexistent copy location -> %', copy_location
                USING HINT = 'Please check your copy_location';
           END IF;
        END IF;

        INSERT INTO config.circ_matrix_matchpoint
        (org_unit, grp, active, circ_modifier, marc_type, marc_form,
         marc_bib_level, marc_vr_format, copy_circ_lib, copy_owning_lib,
         user_home_ou, ref_flag, juvenile_flag, is_renewal, usr_age_lower_bound,
         usr_age_upper_bound, circulate, duration_rule, recurring_fine_rule,
         max_fine_rule, hard_due_date, renewals, grace_period, script_test,
         total_copy_hold_ratio, available_copy_hold_ratio, item_age,
         copy_location)
        VALUES
        (org_unit_id, grp_id, active, circ_modifier, marc_type, marc_form,
         marc_bib_level, marc_vr_format, copy_circ_lib_id, copy_owning_lib_id,
         user_home_ou_id, ref_flag, juvenile_flag, is_renewal,
         usr_age_lower_bound, usr_age_upper_bound, circulate, duration_rule_id,
         recurring_fine_rule_id, max_fine_rule_id, hard_due_date_id, renewals,
         grace_period, script_test, total_copy_hold_ratio,
         available_copy_hold_ratio, item_age, copy_location_id)
         RETURNING id into ccmm_id;

         RETURN ccmm_id;

END;
$$ LANGUAGE plpgsql;
