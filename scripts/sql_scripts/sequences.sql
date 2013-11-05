-- nodes
CREATE SEQUENCE node_id_seq;
SELECT setval('node_id_seq', (SELECT max(node_id)+1 from nodes));

-- ways
CREATE SEQUENCE way_id_seq;
SELECT setval('way_id_seq', (SELECT max(way_id)+1 from ways));

-- relations
CREATE SEQUENCE relation_id_seq;
SELECT setval('relation_id_seq', (SELECT max(relation_id)+1 from relations));


-- changesets
SELECT setval('changesets_id_seq', (SELECT max(id)+1 from changesets));

