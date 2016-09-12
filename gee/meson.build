valagee_sources = [
    'arraylist.vala',
    'collection.vala',
    'hashmap.vala',
    'hashset.vala',
    'iterable.vala',
    'iterator.vala',
    'list.vala',
    'mapiterator.vala',
    'map.vala',
    'set.vala']
valagee_lib = library('valagee', valagee_sources, dependencies: [glib, gobject])

valagee = declare_dependency(link_with: valagee_lib,
                             include_directories: include_directories('.'))
