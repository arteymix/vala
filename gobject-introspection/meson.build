gidl_sources = [
    'gidlmodule.c',
    'gidlnode.c',
    'gidlparser.c',
    'gidlwriter.c',
    'gmetadata.c',
    'scanner.c',
    'scannerlexer.c',
    'scannerparser.c']
gidl_lib = library('gidl', gidl_sources, dependencies: [glib, gthread, gobject, gmodule])
gidl = declare_dependency(link_with: gidl_lib, include_directories: include_directories('.'))
