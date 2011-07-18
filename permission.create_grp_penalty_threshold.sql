/*
 * Copyright (C) 2011 Merrimack Valley Library Consortium
 * Jason Stephenson <jstephenson@mvlc.org>
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

-- A helper function to make permission.grp_penalty_threshold entries.
CREATE OR REPLACE FUNCTION permission.create_grp_penalty_threshold(
    grp TEXT,
    org TEXT,
    penalty TEXT,
    threshold NUMERIC(8,2))
RETURNS VOID AS $$
DECLARE
    grp_id INT;
    org_unit_id INT;
    penalty_id INT;
BEGIN

    SELECT INTO grp_id id
    FROM permission.grp_tree
    WHERE name = grp;

    SELECT INTO org_unit_id id
    FROM actor.org_unit
    WHERE shortname = org;

    SELECT INTO penalty_id id
    FROM config.standing_penalty
    WHERE name = penalty;

    INSERT INTO permission.grp_penalty_threshold
    (grp, org_unit, penalty, threshold)
    VALUES (grp_id, org_unit_id, penalty_id, threshold);

END;
$$ LANGUAGE plpgsql;
