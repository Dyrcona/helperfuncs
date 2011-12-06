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

-- A helper function to make config.hold_matrix_matchpoint entries.
CREATE OR REPLACE FUNCTION config.create_hold_matrix_matchpoint(
    active                  BOOL = TRUE,
    strict_ou_match         BOOL = FALSE,
    user_home_ou            TEXT = NULL,
    request_ou              TEXT = NULL,
    pickup_ou               TEXT = NULL,
    item_owning_ou          TEXT = NULL,
    item_circ_ou            TEXT = NULL,
    usr_grp                 TEXT = 'Users',
    requestor_grp           TEXT = 'Users',
    circ_modifier           TEXT = NULL,
    marc_type               TEXT = NULL,
    marc_form               TEXT = NULL,
    marc_bib_level          TEXT = NULL,
    marc_vr_format          TEXT = NULL,
    juvenile_flag           BOOL = NULL,
    ref_flag                BOOL = NULL,
    holdable                BOOL = TRUE,
    distance_is_from_owner  BOOL = FALSE,
    transit_range           INT = NULL,
    max_holds               INT = NULL,
    include_frozen_holds    BOOL = TRUE,
    stop_blocked_user       BOOL = FALSE,
    age_hold_protect_rule   TEXT = NULL,
    item_age                INTERVAL = NULL)
RETURNS VOID AS $$
DECLARE
    user_home_ou_id            INT = NULL;
    request_ou_id              INT = NULL;
    pickup_ou_id               INT = NULL;
    item_owning_ou_id          INT = NULL;
    item_circ_ou_id            INT = NULL;
    usr_grp_id                 INT = NULL;
    requestor_grp_id           INT = NULL;
    age_hold_protect_rule_id INT = NULL;
BEGIN

    IF user_home_ou IS NOT NULL THEN
        SELECT INTO user_home_ou_id id
        FROM actor.org_unit
        WHERE shortname = user_home_ou;
    END IF;

    IF request_ou IS NOT NULL THEN
        SELECT INTO request_ou_id id
        FROM actor.org_unit
        WHERE shortname = request_ou;
    END IF;

    IF pickup_ou IS NOT NULL THEN
        SELECT INTO pickup_ou_id id
        FROM actor.org_unit
        WHERE shortname = pickup_ou;
    END IF;

    IF item_owning_ou IS NOT NULL THEN
        SELECT INTO item_owning_ou_id id
        FROM actor.org_unit
        WHERE shortname = item_owning_ou;
    END IF;

    IF item_circ_ou IS NOT NULL THEN
        SELECT INTO item_circ_ou_id id
        FROM actor.org_unit
        WHERE shortname = item_circ_ou;
    END IF;

    IF usr_grp IS NOT NULL THEN
        SELECT INTO usr_grp_id id
        FROM permission.grp_tree
        WHERE name = usr_grp;
    END IF;

    IF requestor_grp IS NOT NULL THEN
        SELECT INTO requestor_grp_id id
        FROM permission.grp_tree
        WHERE name = requestor_grp;
    END IF;

    IF age_hold_protect_rule IS NOT NULL THEN
        SELECT INTO age_hold_protect_rule_id id
        FROM config.rule_age_hold_protect
        WHERE name = age_hold_protect_rule;
    END IF;

    INSERT INTO config.hold_matrix_matchpoint
    (active, strict_ou_match, user_home_ou, request_ou, pickup_ou,
     item_owning_ou, item_circ_ou, usr_grp, requestor_grp, circ_modifier,
     marc_type, marc_form, marc_bib_level, marc_vr_format, juvenile_flag,
     ref_flag, holdable, distance_is_from_owner, transit_range, max_holds,
     include_frozen_holds, stop_blocked_user, age_hold_protect_rule, item_age)
    VALUES
    (active, strict_ou_match, user_home_ou_id, request_ou_id, pickup_ou_id,
     item_owning_ou_id, item_circ_ou_id, usr_grp_id, requestor_grp_id,
     circ_modifier, marc_type, marc_form, marc_bib_level, marc_vr_format,
     juvenile_flag, ref_flag, holdable, distance_is_from_owner, transit_range,
     max_holds, include_frozen_holds, stop_blocked_user,
     age_hold_protect_rule_id, item_age);

END;
$$ LANGUAGE plpgsql;
