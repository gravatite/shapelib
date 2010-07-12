
static VALUE sp_to_h(VALUE obj)
{
    VALUE h;
    h = rb_hash_new();
    rb_hash_aset(h, CSTR2SYM("shape_type"), sp_shape_type(obj));
    rb_hash_aset(h, CSTR2SYM("shape_id"), sp_shape_id(obj));
    rb_hash_aset(h, CSTR2SYM("maxbound"), sp_maxbound(obj));
    rb_hash_aset(h, CSTR2SYM("minbound"), sp_minbound(obj));
    rb_hash_aset(h, CSTR2SYM("mvals"), sp_mvals(obj));
    rb_hash_aset(h, CSTR2SYM("n_parts"), sp_n_parts(obj));
    rb_hash_aset(h, CSTR2SYM("n_vertices"), sp_n_vertices(obj));
    rb_hash_aset(h, CSTR2SYM("part_start"), sp_part_start(obj));
    rb_hash_aset(h, CSTR2SYM("part_type"), sp_part_type(obj));
    rb_hash_aset(h, CSTR2SYM("shape_id"), sp_shape_id(obj));
    rb_hash_aset(h, CSTR2SYM("shape_type"), sp_shape_type(obj));
    rb_hash_aset(h, CSTR2SYM("xvals"), sp_xvals(obj));
    rb_hash_aset(h, CSTR2SYM("yvals"), sp_yvals(obj));
    rb_hash_aset(h, CSTR2SYM("zvals"), sp_zvals(obj));
    Attr_to_Hash(h, obj);
    return h;
}

static method_table_entry sp_methods[] = {
    { "[]",		sp_field_get, 1 },
    { "[]=",		sp_field_set, 2 },
    { "maxbound",	sp_maxbound, 0 },
    { "minbound",	sp_minbound, 0 },
    { "mvals",		sp_mvals, 0 },
    { "n_parts",	sp_n_parts, 0 },
    { "n_vertices",	sp_n_vertices, 0 },
    { "part_start",	sp_part_start, 0 },
    { "part_type",	sp_part_type, 0 },
    { "shape_type",	sp_shape_type, 0 },
    { "shape_id",	sp_shape_id, 0 },
    { "to_h",		sp_to_h, 0 },
    { "to_s",		sp_wkt, 0 },
    { "rewind_polygon",	sp_rewind, 0 },
    { "wkt",		sp_wkt, 0 },
    { "xvals",		sp_xvals, 0 },
    { "yvals",		sp_yvals, 0 },
    { "zvals",		sp_zvals, 0 },
    { NULL, NULL, 0 }
};

static method_table_entry pt_methods[] = {
    { "m",		pt_m, 0 },
    { "wkt",		pt_wkt, 0 },
    { "x",		pt_x, 0 },
    { "y",		pt_y, 0 },
    { "z",		pt_z, 0 },
    { NULL, NULL, 0 }
};
