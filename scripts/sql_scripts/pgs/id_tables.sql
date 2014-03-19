CREATE TABLE id_fields (
  key text,
  keys text[],
  type text NOT NULL,
  label text NOT NULL,
  geometry text,
  default text,
  indexed boolean,
  options text[],
  universal boolean NOT NULL DEFAULT false,
  icon text,
  placeholder text,
  strings json
);

comment on column id_fields.key is 'Tag key whose value is to be displayed';
comment on column id_fields.keys is 'Tag keys whose value is to be displayed';
comment on column id_fields.type is 'Type of field';
comment on column id_fields.label is 'English label for the form';
--comment on column id_fields.geometry is '';
--comment on column id_fields.default is '';
--comment on column id_fields.indexed is '';
--comment on column id_fields.options is '';
--comment on column id_fields.universal is '';
--comment on column id_fields.icon is '';
--comment on column id_fields.placeholder is '';
--comment on column id_fields.strings is '';

CREATE TABLE id_presets (
  name text NOT NULL,
  geometry text[], NOT NULL,
  tags json NOT NULL,
  addTags json,
  removeTags json,
  fields text[],
  icon text,
  maki text,
  terms text[],
  searchable boolean DEFAULT true,
  matchScore numeric,
  zindex integer,
  render text[]
);
comment on column id_presets.name is 'The English name for the feature';
comment on column id_presets.geometry is 'Valid geometry types for the feature';
comment on column id_presets.tags is 'Tags that must be present for the preset to match';
comment on column id_presets.addTags is 'Tags that are added when changing to the preset (default is the same value as tags)';
comment on column id_presets.removeTags is 'Tags that are removed when changing to another preset (default is the same value as tags)';
comment on column id_presets.fields is 'Form fields that are displayed for the preset';
comment on column id_presets.icon is 'Name of preset icon which represents this preset';
comment on column id_presets.maki is 'Custom type used to allow National Park Service Icons (npmaki) along with other maki based libraries';
comment on column id_presets.terms is 'English synonyms or related terms';
comment on column id_presets.searchable is 'Whether or not the preset will be suggested via search';
comment on column id_presets.matchScore is 'The quality score this preset will receive when being compared with other matches (higher is better)';
comment on column id_presets.zindex is 'Order in which the layer renders in mapnik, a higher number shows up in front of a lower number';
comment on column id_presets.render is 'geometry types that will render in mapnik';


