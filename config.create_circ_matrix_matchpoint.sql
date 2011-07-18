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
    item_age             INTERVAL = NULL)
RETURNS VOID AS $$
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
        END IF;

        IF recurring_fine_rule IS NOT NULL THEN
           SELECT INTO recurring_fine_rule_id id
           FROM config.rule_recurring_fine
           WHERE name = recurring_fine_rule;
        END IF;

        IF max_fine_rule IS NOT NULL THEN
           SELECT INTO max_fine_rule_id id
           FROM config.rule_max_fine
           WHERE name = max_fine_rule;
        END IF;

        IF hard_due_date IS NOT NULL THEN
           SELECT INTO hard_due_date_id id
           FROM config.hard_due_date
           WHERE name = hard_due_date;
        END IF;

        IF copy_circ_lib IS NOT NULL THEN
           SELECT INTO copy_circ_lib_id id
           FROM actor.org_unit
           WHERE shortname = copy_circ_lib;
        END IF;

        IF copy_owning_lib IS NOT NULL THEN
           SELECT INTO copy_owning_lib_id id
           FROM actor.org_unit
           WHERE shortname = copy_owning_lib;
        END IF;

        IF user_home_ou IS NOT NULL THEN
           SELECT INTO user_home_ou_id id
           FROM actor.org_unit
           WHERE shortname = user_home_ou;
        END IF;

        INSERT INTO config.circ_matrix_matchpoint
        (org_unit, grp, active, circ_modifier, marc_type, marc_form,
         marc_bib_level, marc_vr_format, copy_circ_lib, copy_owning_lib,
         user_home_ou, ref_flag, juvenile_flag, is_renewal, usr_age_lower_bound,
         usr_age_upper_bound, circulate, duration_rule, recurring_fine_rule,
         max_fine_rule, hard_due_date, renewals, grace_period, script_test,
         total_copy_hold_ratio, available_copy_hold_ratio, item_age)
        VALUES
        (org_unit_id, grp_id, active, circ_modifier, marc_type, marc_form,
         marc_bib_level, marc_vr_format, copy_circ_lib_id, copy_owning_lib_id,
         user_home_ou_id, ref_flag, juvenile_flag, is_renewal,
         usr_age_lower_bound, usr_age_upper_bound, circulate, duration_rule_id,
         recurring_fine_rule_id, max_fine_rule_id, hard_due_date_id, renewals,
         grace_period, script_test, total_copy_hold_ratio,
         available_copy_hold_ratio, item_age);

END;
$$ LANGUAGE plpgsql;
