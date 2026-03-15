"""Common build setting rules for toolchains_msvc."""

def _string_enum_flag_impl(ctx):
    value = ctx.build_setting_value
    allowed = ctx.attr.allowed_values

    if allowed and value not in allowed:
        fail("Invalid value '{}' for flag {}: must be one of {}".format(value, ctx.label, ", ".join(allowed)))

    return []

string_enum_flag = rule(
    implementation = _string_enum_flag_impl,
    build_setting = config.string(flag = True),
    attrs = {
        "allowed_values": attr.string_list(),
    },
)
