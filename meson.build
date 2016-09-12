project('Vala', 'c', 'vala')

if not meson.is_subproject()
add_global_arguments(['-Wno-deprecated-declarations',
                      '-Wno-discarded-qualifiers',
                      '-Wno-incompatible-pointer-types',
                      '-Wno-unused'], language: 'c')
endif

glib = dependency('glib-2.0')
gthread = dependency('gthread-2.0')
gobject = dependency('gobject-2.0')
gmodule = dependency('gmodule-2.0')
gee = dependency('gee-0.8')

subdir('gee')
subdir('vala')
subdir('ccode')
subdir('codegen')
subdir('compiler')
subdir('gobject-introspection')
subdir('vapigen')
