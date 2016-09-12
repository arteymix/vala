vapigen_sources = [
    'valagidlparser.vala',
#'valavapicheck.vala',
    'valavapigen.vala',
    '../gobject-introspection/gidl.vapi']
executable('vapigen', vapigen_sources, dependencies: [glib, gobject, valagee, vala, gidl])
executable('vapicheck', ['valavapicheck.vala', '../gobject-introspection/gidl.vapi'], dependencies: [glib, gobject, valagee, vala, gidl])
