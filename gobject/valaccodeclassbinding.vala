/* valaccodeclassbinding.vala
 *
 * Copyright (C) 2006-2008  Jürg Billeter, Raffaele Sandrini
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 */

using GLib;

public class Vala.CCodeClassBinding : CCodeTypesymbolBinding {
	public Class cl { get; set; }

	public CCodeClassBinding (CCodeGenerator codegen, Class cl) {
		this.cl = cl;
		this.codegen = codegen;
	}

	public override void emit () {
		var old_symbol = codegen.current_symbol;
		var old_type_symbol = codegen.current_type_symbol;
		var old_class = codegen.current_class;
		var old_instance_struct = codegen.instance_struct;
		var old_type_struct = codegen.type_struct;
		var old_instance_priv_struct = codegen.instance_priv_struct;
		var old_prop_enum = codegen.prop_enum;
		var old_class_init_fragment = codegen.class_init_fragment;
		var old_instance_init_fragment = codegen.instance_init_fragment;
		var old_instance_dispose_fragment = codegen.instance_dispose_fragment;
		codegen.current_symbol = cl;
		codegen.current_type_symbol = cl;
		codegen.current_class = cl;
		
		bool is_gtypeinstance = cl.is_subtype_of (codegen.gtypeinstance_type);
		bool is_gobject = cl.is_subtype_of (codegen.gobject_type);
		bool is_fundamental = (cl.base_class == codegen.gtypeinstance_type);

		if (cl.get_cname().len () < 3) {
			cl.error = true;
			Report.error (cl.source_reference, "Class name `%s' is too short".printf (cl.get_cname ()));
			return;
		}

		if (!cl.is_static) {
			codegen.instance_struct = new CCodeStruct ("_%s".printf (cl.get_cname ()));
			codegen.type_struct = new CCodeStruct ("_%sClass".printf (cl.get_cname ()));
			codegen.instance_priv_struct = new CCodeStruct ("_%sPrivate".printf (cl.get_cname ()));
			codegen.prop_enum = new CCodeEnum ();
			codegen.prop_enum.add_value (new CCodeEnumValue ("%s_DUMMY_PROPERTY".printf (cl.get_upper_case_cname (null))));
			codegen.class_init_fragment = new CCodeFragment ();
			codegen.instance_init_fragment = new CCodeFragment ();
			codegen.instance_dispose_fragment = new CCodeFragment ();
		}

		CCodeFragment decl_frag;
		CCodeFragment def_frag;
		if (cl.access != SymbolAccessibility.PRIVATE) {
			decl_frag = codegen.header_type_declaration;
			def_frag = codegen.header_type_definition;
		} else {
			decl_frag = codegen.source_type_declaration;
			def_frag = codegen.source_type_definition;
		}

		if (is_gtypeinstance) {
			decl_frag.append (new CCodeNewline ());
			var macro = "(%s_get_type ())".printf (cl.get_lower_case_cname (null));
			decl_frag.append (new CCodeMacroReplacement (cl.get_upper_case_cname ("TYPE_"), macro));

			macro = "(G_TYPE_CHECK_INSTANCE_CAST ((obj), %s, %s))".printf (cl.get_upper_case_cname ("TYPE_"), cl.get_cname ());
			decl_frag.append (new CCodeMacroReplacement ("%s(obj)".printf (cl.get_upper_case_cname (null)), macro));

			macro = "(G_TYPE_CHECK_CLASS_CAST ((klass), %s, %sClass))".printf (cl.get_upper_case_cname ("TYPE_"), cl.get_cname ());
			decl_frag.append (new CCodeMacroReplacement ("%s_CLASS(klass)".printf (cl.get_upper_case_cname (null)), macro));

			macro = "(G_TYPE_CHECK_INSTANCE_TYPE ((obj), %s))".printf (cl.get_upper_case_cname ("TYPE_"));
			decl_frag.append (new CCodeMacroReplacement ("%s(obj)".printf (cl.get_upper_case_cname ("IS_")), macro));

			macro = "(G_TYPE_CHECK_CLASS_TYPE ((klass), %s))".printf (cl.get_upper_case_cname ("TYPE_"));
			decl_frag.append (new CCodeMacroReplacement ("%s_CLASS(klass)".printf (cl.get_upper_case_cname ("IS_")), macro));

			macro = "(G_TYPE_INSTANCE_GET_CLASS ((obj), %s, %sClass))".printf (cl.get_upper_case_cname ("TYPE_"), cl.get_cname ());
			decl_frag.append (new CCodeMacroReplacement ("%s_GET_CLASS(obj)".printf (cl.get_upper_case_cname (null)), macro));
			decl_frag.append (new CCodeNewline ());
		}


		if (!cl.is_static && cl.source_reference.file.cycle == null) {
			decl_frag.append (new CCodeTypeDefinition ("struct %s".printf (codegen.instance_struct.name), new CCodeVariableDeclarator (cl.get_cname ())));
		}

		if (cl.base_class != null) {
			codegen.instance_struct.add_field (cl.base_class.get_cname (), "parent_instance");
			if (is_fundamental) {
				codegen.instance_struct.add_field ("volatile int", "ref_count");
			}
		}

		if (is_gtypeinstance) {
			if (cl.source_reference.file.cycle == null) {
				decl_frag.append (new CCodeTypeDefinition ("struct %s".printf (codegen.type_struct.name), new CCodeVariableDeclarator ("%sClass".printf (cl.get_cname ()))));
			}
			decl_frag.append (new CCodeTypeDefinition ("struct %s".printf (codegen.instance_priv_struct.name), new CCodeVariableDeclarator ("%sPrivate".printf (cl.get_cname ()))));

			codegen.instance_struct.add_field ("%sPrivate *".printf (cl.get_cname ()), "priv");
			if (is_fundamental) {
				codegen.type_struct.add_field ("GTypeClass", "parent_class");
				codegen.type_struct.add_field ("void", "(*finalize) (%s *self)".printf (cl.get_cname ()));
			} else {
				codegen.type_struct.add_field ("%sClass".printf (cl.base_class.get_cname ()), "parent_class");
			}
		}

		if (!cl.is_static) {
			if (cl.source_reference.comment != null) {
				def_frag.append (new CCodeComment (cl.source_reference.comment));
			}
			def_frag.append (codegen.instance_struct);
		}

		if (is_gtypeinstance) {
			def_frag.append (codegen.type_struct);
			/* only add the *Private struct if it is not empty, i.e. we actually have private data */
			if (cl.has_private_fields || cl.get_type_parameters ().size > 0) {
				codegen.source_type_member_declaration.append (codegen.instance_priv_struct);
				var macro = "(G_TYPE_INSTANCE_GET_PRIVATE ((o), %s, %sPrivate))".printf (cl.get_upper_case_cname ("TYPE_"), cl.get_cname ());
				codegen.source_type_member_declaration.append (new CCodeMacroReplacement ("%s_GET_PRIVATE(o)".printf (cl.get_upper_case_cname (null)), macro));
			}
			codegen.source_type_member_declaration.append (codegen.prop_enum);
		}

		cl.accept_children (codegen);

		if (is_gtypeinstance) {
			if (is_fundamental) {
				var ref_count = new CCodeAssignment (new CCodeMemberAccess.pointer (new CCodeIdentifier ("self"), "ref_count"), new CCodeConstant ("1"));
				codegen.instance_init_fragment.append (new CCodeExpressionStatement (ref_count));
			} else if (is_gobject) {
				if (class_has_readable_properties (cl) || cl.get_type_parameters ().size > 0) {
					add_get_property_function (cl);
				}
				if (class_has_writable_properties (cl) || cl.get_type_parameters ().size > 0) {
					add_set_property_function (cl);
				}
			}
			add_class_init_function (cl);
			
			foreach (DataType base_type in cl.get_base_types ()) {
				if (base_type.data_type is Interface) {
					add_interface_init_function (cl, (Interface) base_type.data_type);
				}
			}
			
			add_instance_init_function (cl);

			if (is_gobject) {
				if (cl.get_fields ().size > 0 || cl.destructor != null) {
					add_dispose_function (cl);
				}
			}

			var type_fun = new ClassRegisterFunction (cl);
			type_fun.init_from_type (codegen.in_plugin);
			if (cl.access != SymbolAccessibility.PRIVATE) {
				codegen.header_type_member_declaration.append (type_fun.get_declaration ());
			} else {
				codegen.source_type_member_declaration.append (type_fun.get_declaration ());
			}
			codegen.source_type_member_definition.append (type_fun.get_definition ());
			
			if (codegen.in_plugin) {
				// FIXME resolve potential dependency issues, i.e. base types have to be registered before derived types
				var register_call = new CCodeFunctionCall (new CCodeIdentifier ("%s_register_type".printf (cl.get_lower_case_cname (null))));
				register_call.add_argument (new CCodeIdentifier (codegen.module_init_param_name));
				codegen.module_init_fragment.append (new CCodeExpressionStatement (register_call));
			}

			if (is_fundamental) {
				var ref_fun = new CCodeFunction (cl.get_lower_case_cprefix () + "ref", "gpointer");
				var unref_fun = new CCodeFunction (cl.get_lower_case_cprefix () + "unref", "void");
				if (cl.access == SymbolAccessibility.PRIVATE) {
					ref_fun.modifiers = CCodeModifiers.STATIC;
					unref_fun.modifiers = CCodeModifiers.STATIC;
				}

				ref_fun.add_parameter (new CCodeFormalParameter ("instance", "gpointer"));
				unref_fun.add_parameter (new CCodeFormalParameter ("instance", "gpointer"));

				if (cl.access != SymbolAccessibility.PRIVATE) {
					codegen.header_type_member_declaration.append (ref_fun.copy ());
					codegen.header_type_member_declaration.append (unref_fun.copy ());
				} else {
					codegen.source_type_member_declaration.append (ref_fun.copy ());
					codegen.source_type_member_declaration.append (unref_fun.copy ());
				}

				var ref_block = new CCodeBlock ();
				var unref_block = new CCodeBlock ();

				var cdecl = new CCodeDeclaration (cl.get_cname () + "*");
				cdecl.add_declarator (new CCodeVariableDeclarator.with_initializer ("self", new CCodeIdentifier ("instance")));
				ref_block.add_statement (cdecl);
				unref_block.add_statement (cdecl);

				var ref_count = new CCodeMemberAccess.pointer (new CCodeIdentifier ("self"), "ref_count");

				var ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_atomic_int_inc"));
				ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, ref_count));
				ref_block.add_statement (new CCodeExpressionStatement (ccall));

				ref_block.add_statement (new CCodeReturnStatement (new CCodeIdentifier ("instance")));

				var destroy_block = new CCodeBlock ();
				var get_class = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_CLASS".printf (cl.get_upper_case_cname (null))));
				get_class.add_argument (new CCodeIdentifier ("self"));
				var finalize = new CCodeMemberAccess.pointer (get_class, "finalize");
				var finalize_call = new CCodeFunctionCall (finalize);
				finalize_call.add_argument (new CCodeIdentifier ("self"));
				//destroy_block.add_statement (new CCodeExpressionStatement (finalize_call));
				var free = new CCodeFunctionCall (new CCodeIdentifier ("g_type_free_instance"));
				free.add_argument (new CCodeCastExpression (new CCodeIdentifier ("self"), "GTypeInstance *"));
				destroy_block.add_statement (new CCodeExpressionStatement (free));

				ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_atomic_int_dec_and_test"));
				ccall.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, ref_count));
				unref_block.add_statement (new CCodeIfStatement (ccall, destroy_block));

				ref_fun.block = ref_block;
				unref_fun.block = unref_block;

				codegen.source_type_member_definition.append (ref_fun);
				codegen.source_type_member_definition.append (unref_fun);
			}
		} else if (!cl.is_static) {
			var function = new CCodeFunction (cl.get_lower_case_cprefix () + "free", "void");
			if (cl.access == SymbolAccessibility.PRIVATE) {
				function.modifiers = CCodeModifiers.STATIC;
			}

			function.add_parameter (new CCodeFormalParameter ("self", cl.get_cname () + "*"));

			if (cl.access != SymbolAccessibility.PRIVATE) {
				codegen.header_type_member_declaration.append (function.copy ());
			} else {
				codegen.source_type_member_declaration.append (function.copy ());
			}

			var cblock = new CCodeBlock ();

			cblock.add_statement (codegen.instance_dispose_fragment);

			var ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_slice_free"));
			ccall.add_argument (new CCodeIdentifier (cl.get_cname ()));
			ccall.add_argument (new CCodeIdentifier ("self"));
			cblock.add_statement (new CCodeExpressionStatement (ccall));

			function.block = cblock;

			codegen.source_type_member_definition.append (function);
		}

		codegen.current_type_symbol = old_type_symbol;
		codegen.current_class = old_class;
		codegen.instance_struct = old_instance_struct;
		codegen.type_struct = old_type_struct;
		codegen.instance_priv_struct = old_instance_priv_struct;
		codegen.prop_enum = old_prop_enum;
		codegen.class_init_fragment = old_class_init_fragment;
		codegen.instance_init_fragment = old_instance_init_fragment;
		codegen.instance_dispose_fragment = old_instance_dispose_fragment;
	}
	
	private void add_class_init_function (Class cl) {
		var class_init = new CCodeFunction ("%s_class_init".printf (cl.get_lower_case_cname (null)), "void");
		class_init.add_parameter (new CCodeFormalParameter ("klass", "%sClass *".printf (cl.get_cname ())));
		class_init.modifiers = CCodeModifiers.STATIC;
		
		var init_block = new CCodeBlock ();
		class_init.block = init_block;
		
		CCodeFunctionCall ccall;
		
		/* save pointer to parent class */
		var parent_decl = new CCodeDeclaration ("gpointer");
		var parent_var_decl = new CCodeVariableDeclarator ("%s_parent_class".printf (cl.get_lower_case_cname (null)));
		parent_var_decl.initializer = new CCodeConstant ("NULL");
		parent_decl.add_declarator (parent_var_decl);
		parent_decl.modifiers = CCodeModifiers.STATIC;
		codegen.source_type_member_declaration.append (parent_decl);
		ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_type_class_peek_parent"));
		ccall.add_argument (new CCodeIdentifier ("klass"));
		var parent_assignment = new CCodeAssignment (new CCodeIdentifier ("%s_parent_class".printf (cl.get_lower_case_cname (null))), ccall);
		init_block.add_statement (new CCodeExpressionStatement (parent_assignment));
		
		/* add struct for private fields */
		if (cl.has_private_fields || cl.get_type_parameters ().size > 0) {
			ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_type_class_add_private"));
			ccall.add_argument (new CCodeIdentifier ("klass"));
			ccall.add_argument (new CCodeConstant ("sizeof (%sPrivate)".printf (cl.get_cname ())));
			init_block.add_statement (new CCodeExpressionStatement (ccall));
		}

		if (cl.is_subtype_of (codegen.gobject_type)) {
			/* set property handlers */
			ccall = new CCodeFunctionCall (new CCodeIdentifier ("G_OBJECT_CLASS"));
			ccall.add_argument (new CCodeIdentifier ("klass"));
			if (class_has_readable_properties (cl) || cl.get_type_parameters ().size > 0) {
				init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (ccall, "get_property"), new CCodeIdentifier ("%s_get_property".printf (cl.get_lower_case_cname (null))))));
			}
			if (class_has_writable_properties (cl) || cl.get_type_parameters ().size > 0) {
				init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (ccall, "set_property"), new CCodeIdentifier ("%s_set_property".printf (cl.get_lower_case_cname (null))))));
			}
		
			/* set constructor */
			if (cl.constructor != null) {
				var ccast = new CCodeFunctionCall (new CCodeIdentifier ("G_OBJECT_CLASS"));
				ccast.add_argument (new CCodeIdentifier ("klass"));
				init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (ccast, "constructor"), new CCodeIdentifier ("%s_constructor".printf (cl.get_lower_case_cname (null))))));
			}

			/* set dispose function */
			if (cl.get_fields ().size > 0 || cl.destructor != null) {
				var ccast = new CCodeFunctionCall (new CCodeIdentifier ("G_OBJECT_CLASS"));
				ccast.add_argument (new CCodeIdentifier ("klass"));
				init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (ccast, "dispose"), new CCodeIdentifier ("%s_dispose".printf (cl.get_lower_case_cname (null))))));
			}
		}

		/* connect overridden methods */
		foreach (Method m in cl.get_methods ()) {
			if (m.base_method == null) {
				continue;
			}
			var base_type = m.base_method.parent_symbol;
			
			var ccast = new CCodeFunctionCall (new CCodeIdentifier ("%s_CLASS".printf (((Class) base_type).get_upper_case_cname (null))));
			ccast.add_argument (new CCodeIdentifier ("klass"));
			init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (ccast, m.base_method.vfunc_name), new CCodeIdentifier (m.get_real_cname ()))));
		}

		if (cl.is_subtype_of (codegen.gobject_type)) {
			/* create type, dup_func, and destroy_func properties for generic types */
			foreach (TypeParameter type_param in cl.get_type_parameters ()) {
				string func_name, enum_value;
				CCodeConstant func_name_constant;
				CCodeFunctionCall cinst, cspec;

				func_name = "%s_type".printf (type_param.name.down ());
				func_name_constant = new CCodeConstant ("\"%s-type\"".printf (type_param.name.down ()));
				enum_value = "%s_%s".printf (cl.get_lower_case_cname (null), func_name).up ();
				cinst = new CCodeFunctionCall (new CCodeIdentifier ("g_object_class_install_property"));
				cinst.add_argument (ccall);
				cinst.add_argument (new CCodeConstant (enum_value));
				cspec = new CCodeFunctionCall (new CCodeIdentifier ("g_param_spec_gtype"));
				cspec.add_argument (func_name_constant);
				cspec.add_argument (new CCodeConstant ("\"type\""));
				cspec.add_argument (new CCodeConstant ("\"type\""));
				cspec.add_argument (new CCodeIdentifier ("G_TYPE_NONE"));
				cspec.add_argument (new CCodeConstant ("G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY"));
				cinst.add_argument (cspec);
				init_block.add_statement (new CCodeExpressionStatement (cinst));
				codegen.prop_enum.add_value (new CCodeEnumValue (enum_value));

				codegen.instance_priv_struct.add_field ("GType", func_name);


				func_name = "%s_dup_func".printf (type_param.name.down ());
				func_name_constant = new CCodeConstant ("\"%s-dup-func\"".printf (type_param.name.down ()));
				enum_value = "%s_%s".printf (cl.get_lower_case_cname (null), func_name).up ();
				cinst = new CCodeFunctionCall (new CCodeIdentifier ("g_object_class_install_property"));
				cinst.add_argument (ccall);
				cinst.add_argument (new CCodeConstant (enum_value));
				cspec = new CCodeFunctionCall (new CCodeIdentifier ("g_param_spec_pointer"));
				cspec.add_argument (func_name_constant);
				cspec.add_argument (new CCodeConstant ("\"dup func\""));
				cspec.add_argument (new CCodeConstant ("\"dup func\""));
				cspec.add_argument (new CCodeConstant ("G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY"));
				cinst.add_argument (cspec);
				init_block.add_statement (new CCodeExpressionStatement (cinst));
				codegen.prop_enum.add_value (new CCodeEnumValue (enum_value));

				codegen.instance_priv_struct.add_field ("GBoxedCopyFunc", func_name);


				func_name = "%s_destroy_func".printf (type_param.name.down ());
				func_name_constant = new CCodeConstant ("\"%s-destroy-func\"".printf (type_param.name.down ()));
				enum_value = "%s_%s".printf (cl.get_lower_case_cname (null), func_name).up ();
				cinst = new CCodeFunctionCall (new CCodeIdentifier ("g_object_class_install_property"));
				cinst.add_argument (ccall);
				cinst.add_argument (new CCodeConstant (enum_value));
				cspec = new CCodeFunctionCall (new CCodeIdentifier ("g_param_spec_pointer"));
				cspec.add_argument (func_name_constant);
				cspec.add_argument (new CCodeConstant ("\"destroy func\""));
				cspec.add_argument (new CCodeConstant ("\"destroy func\""));
				cspec.add_argument (new CCodeConstant ("G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY"));
				cinst.add_argument (cspec);
				init_block.add_statement (new CCodeExpressionStatement (cinst));
				codegen.prop_enum.add_value (new CCodeEnumValue (enum_value));

				codegen.instance_priv_struct.add_field ("GDestroyNotify", func_name);
			}

			/* create properties */
			var props = cl.get_properties ();
			foreach (Property prop in props) {
				// FIXME: omit real struct types for now since they cannot be expressed as gobject property yet
				if (prop.type_reference.is_real_struct_type ()) {
					continue;
				}
				if (prop.access == SymbolAccessibility.PRIVATE) {
					// don't register private properties
					continue;
				}

				if (prop.overrides || prop.base_interface_property != null) {
					var cinst = new CCodeFunctionCall (new CCodeIdentifier ("g_object_class_override_property"));
					cinst.add_argument (ccall);
					cinst.add_argument (new CCodeConstant (prop.get_upper_case_cname ()));
					cinst.add_argument (prop.get_canonical_cconstant ());
				
					init_block.add_statement (new CCodeExpressionStatement (cinst));
				} else {
					var cinst = new CCodeFunctionCall (new CCodeIdentifier ("g_object_class_install_property"));
					cinst.add_argument (ccall);
					cinst.add_argument (new CCodeConstant (prop.get_upper_case_cname ()));
					cinst.add_argument (get_param_spec (prop));
				
					init_block.add_statement (new CCodeExpressionStatement (cinst));
				}
			}
		
			/* create signals */
			foreach (Signal sig in cl.get_signals ()) {
				init_block.add_statement (new CCodeExpressionStatement (get_signal_creation (sig, cl)));
			}
		}

		register_dbus_info ();

		init_block.add_statement (codegen.class_init_fragment);
		
		codegen.source_type_member_definition.append (class_init);
	}
	
	private void add_interface_init_function (Class cl, Interface iface) {
		var iface_init = new CCodeFunction ("%s_%s_interface_init".printf (cl.get_lower_case_cname (null), iface.get_lower_case_cname (null)), "void");
		iface_init.add_parameter (new CCodeFormalParameter ("iface", "%s *".printf (iface.get_type_cname ())));
		iface_init.modifiers = CCodeModifiers.STATIC;
		
		var init_block = new CCodeBlock ();
		iface_init.block = init_block;
		
		CCodeFunctionCall ccall;
		
		/* save pointer to parent vtable */
		string parent_iface_var = "%s_%s_parent_iface".printf (cl.get_lower_case_cname (null), iface.get_lower_case_cname (null));
		var parent_decl = new CCodeDeclaration (iface.get_type_cname () + "*");
		var parent_var_decl = new CCodeVariableDeclarator (parent_iface_var);
		parent_var_decl.initializer = new CCodeConstant ("NULL");
		parent_decl.add_declarator (parent_var_decl);
		parent_decl.modifiers = CCodeModifiers.STATIC;
		codegen.source_type_member_declaration.append (parent_decl);
		ccall = new CCodeFunctionCall (new CCodeIdentifier ("g_type_interface_peek_parent"));
		ccall.add_argument (new CCodeIdentifier ("iface"));
		var parent_assignment = new CCodeAssignment (new CCodeIdentifier (parent_iface_var), ccall);
		init_block.add_statement (new CCodeExpressionStatement (parent_assignment));

		foreach (Method m in cl.get_methods ()) {
			if (m.base_interface_method == null) {
				continue;
			}

			var base_type = m.base_interface_method.parent_symbol;
			if (base_type != iface) {
				continue;
			}
			
			var ciface = new CCodeIdentifier ("iface");
			var cname = m.get_real_cname ();
			if (m.is_abstract || m.is_virtual) {
				// FIXME results in C compiler warning
				cname = m.get_cname ();
			}
			init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (ciface, m.base_interface_method.vfunc_name), new CCodeIdentifier (cname))));
		}
		
		codegen.source_type_member_definition.append (iface_init);
	}
	
	private void add_instance_init_function (Class cl) {
		var instance_init = new CCodeFunction ("%s_init".printf (cl.get_lower_case_cname (null)), "void");
		instance_init.add_parameter (new CCodeFormalParameter ("self", "%s *".printf (cl.get_cname ())));
		instance_init.modifiers = CCodeModifiers.STATIC;
		
		var init_block = new CCodeBlock ();
		instance_init.block = init_block;
		
		if (cl.has_private_fields || cl.get_type_parameters ().size > 0) {
			var ccall = new CCodeFunctionCall (new CCodeIdentifier ("%s_GET_PRIVATE".printf (cl.get_upper_case_cname (null))));
			ccall.add_argument (new CCodeIdentifier ("self"));
			init_block.add_statement (new CCodeExpressionStatement (new CCodeAssignment (new CCodeMemberAccess.pointer (new CCodeIdentifier ("self"), "priv"), ccall)));
		}
		
		init_block.add_statement (codegen.instance_init_fragment);
		
		var init_sym = cl.scope.lookup ("init");
		if (init_sym != null) {
			var init_fun = (Method) init_sym;
			init_block.add_statement (init_fun.body.ccodenode);
		}
		
		codegen.source_type_member_definition.append (instance_init);
	}
	
	private void add_dispose_function (Class cl) {
		var function = new CCodeFunction ("%s_dispose".printf (cl.get_lower_case_cname (null)), "void");
		function.modifiers = CCodeModifiers.STATIC;
		
		function.add_parameter (new CCodeFormalParameter ("obj", "GObject *"));
		
		codegen.source_type_member_declaration.append (function.copy ());


		var cblock = new CCodeBlock ();

		CCodeFunctionCall ccall = new InstanceCast (new CCodeIdentifier ("obj"), cl);

		var cdecl = new CCodeDeclaration ("%s *".printf (cl.get_cname ()));
		cdecl.add_declarator (new CCodeVariableDeclarator.with_initializer ("self", ccall));
		
		cblock.add_statement (cdecl);

		if (cl.destructor != null) {
			cblock.add_statement ((CCodeBlock) cl.destructor.body.ccodenode);
		}

		cblock.add_statement (codegen.instance_dispose_fragment);

		// chain up to dispose function of the base class
		var ccast = new CCodeFunctionCall (new CCodeIdentifier ("G_OBJECT_CLASS"));
		ccast.add_argument (new CCodeIdentifier ("%s_parent_class".printf (cl.get_lower_case_cname (null))));
		ccall = new CCodeFunctionCall (new CCodeMemberAccess.pointer (ccast, "dispose"));
		ccall.add_argument (new CCodeIdentifier ("obj"));
		cblock.add_statement (new CCodeExpressionStatement (ccall));


		function.block = cblock;

		codegen.source_type_member_definition.append (function);
	}

	private bool class_has_readable_properties (Class cl) {
		foreach (Property prop in cl.get_properties ()) {
			if (prop.get_accessor != null) {
				return true;
			}
		}
		return false;
	}

	private bool class_has_writable_properties (Class cl) {
		foreach (Property prop in cl.get_properties ()) {
			if (prop.set_accessor != null) {
				return true;
			}
		}
		return false;
	}

	private void add_get_property_function (Class cl) {
		var get_prop = new CCodeFunction ("%s_get_property".printf (cl.get_lower_case_cname (null)), "void");
		get_prop.modifiers = CCodeModifiers.STATIC;
		get_prop.add_parameter (new CCodeFormalParameter ("object", "GObject *"));
		get_prop.add_parameter (new CCodeFormalParameter ("property_id", "guint"));
		get_prop.add_parameter (new CCodeFormalParameter ("value", "GValue *"));
		get_prop.add_parameter (new CCodeFormalParameter ("pspec", "GParamSpec *"));
		
		var block = new CCodeBlock ();
		
		var ccall = new InstanceCast (new CCodeIdentifier ("object"), cl);
		var cdecl = new CCodeDeclaration ("%s *".printf (cl.get_cname ()));
		cdecl.add_declarator (new CCodeVariableDeclarator.with_initializer ("self", ccall));
		block.add_statement (cdecl);
		
		var cswitch = new CCodeSwitchStatement (new CCodeIdentifier ("property_id"));
		var props = cl.get_properties ();
		foreach (Property prop in props) {
			// FIXME: omit real struct types for now since they cannot be expressed as gobject property yet
			if (prop.get_accessor == null || prop.is_abstract || prop.type_reference.is_real_struct_type ()) {
				continue;
			}
			if (prop.access == SymbolAccessibility.PRIVATE) {
				// don't register private properties
				continue;
			}

			bool is_virtual = prop.base_property != null || prop.base_interface_property != null;

			string prefix = cl.get_lower_case_cname (null);
			if (is_virtual) {
				prefix += "_real";
			}

			var ccase = new CCodeCaseStatement (new CCodeIdentifier (prop.get_upper_case_cname ()));
			var ccall = new CCodeFunctionCall (new CCodeIdentifier ("%s_get_%s".printf (prefix, prop.name)));
			ccall.add_argument (new CCodeIdentifier ("self"));
			var csetcall = new CCodeFunctionCall ();
			csetcall.call = get_value_setter_function (prop.type_reference);
			csetcall.add_argument (new CCodeIdentifier ("value"));
			csetcall.add_argument (ccall);
			ccase.add_statement (new CCodeExpressionStatement (csetcall));
			ccase.add_statement (new CCodeBreakStatement ());
			cswitch.add_case (ccase);
		}
		cswitch.add_default_statement (get_invalid_property_id_warn_statement ());
		cswitch.add_default_statement (new CCodeBreakStatement ());

		block.add_statement (cswitch);

		get_prop.block = block;
		
		codegen.source_type_member_definition.append (get_prop);
	}
	
	private void add_set_property_function (Class cl) {
		var set_prop = new CCodeFunction ("%s_set_property".printf (cl.get_lower_case_cname (null)), "void");
		set_prop.modifiers = CCodeModifiers.STATIC;
		set_prop.add_parameter (new CCodeFormalParameter ("object", "GObject *"));
		set_prop.add_parameter (new CCodeFormalParameter ("property_id", "guint"));
		set_prop.add_parameter (new CCodeFormalParameter ("value", "const GValue *"));
		set_prop.add_parameter (new CCodeFormalParameter ("pspec", "GParamSpec *"));
		
		var block = new CCodeBlock ();
		
		var ccall = new InstanceCast (new CCodeIdentifier ("object"), cl);
		var cdecl = new CCodeDeclaration ("%s *".printf (cl.get_cname ()));
		cdecl.add_declarator (new CCodeVariableDeclarator.with_initializer ("self", ccall));
		block.add_statement (cdecl);
		
		var cswitch = new CCodeSwitchStatement (new CCodeIdentifier ("property_id"));
		var props = cl.get_properties ();
		foreach (Property prop in props) {
			// FIXME: omit real struct types for now since they cannot be expressed as gobject property yet
			if (prop.set_accessor == null || prop.is_abstract || prop.type_reference.is_real_struct_type ()) {
				continue;
			}
			if (prop.access == SymbolAccessibility.PRIVATE) {
				// don't register private properties
				continue;
			}

			bool is_virtual = prop.base_property != null || prop.base_interface_property != null;

			string prefix = cl.get_lower_case_cname (null);
			if (is_virtual) {
				prefix += "_real";
			}

			var ccase = new CCodeCaseStatement (new CCodeIdentifier (prop.get_upper_case_cname ()));
			var ccall = new CCodeFunctionCall (new CCodeIdentifier ("%s_set_%s".printf (prefix, prop.name)));
			ccall.add_argument (new CCodeIdentifier ("self"));
			var cgetcall = new CCodeFunctionCall ();
			if (prop.type_reference.data_type != null) {
				cgetcall.call = new CCodeIdentifier (prop.type_reference.data_type.get_get_value_function ());
			} else {
				cgetcall.call = new CCodeIdentifier ("g_value_get_pointer");
			}
			cgetcall.add_argument (new CCodeIdentifier ("value"));
			ccall.add_argument (cgetcall);
			ccase.add_statement (new CCodeExpressionStatement (ccall));
			ccase.add_statement (new CCodeBreakStatement ());
			cswitch.add_case (ccase);
		}
		cswitch.add_default_statement (get_invalid_property_id_warn_statement ());
		cswitch.add_default_statement (new CCodeBreakStatement ());

		block.add_statement (cswitch);

		/* type, dup func, and destroy func properties for generic types */
		foreach (TypeParameter type_param in cl.get_type_parameters ()) {
			string func_name, enum_value;
			CCodeCaseStatement ccase;
			CCodeMemberAccess cfield;
			CCodeFunctionCall cgetcall;

			func_name = "%s_type".printf (type_param.name.down ());
			enum_value = "%s_%s".printf (cl.get_lower_case_cname (null), func_name).up ();
			ccase = new CCodeCaseStatement (new CCodeIdentifier (enum_value));
			cfield = new CCodeMemberAccess.pointer (new CCodeMemberAccess.pointer (new CCodeIdentifier ("self"), "priv"), func_name);
			cgetcall = new CCodeFunctionCall (new CCodeIdentifier ("g_value_get_gtype"));
			cgetcall.add_argument (new CCodeIdentifier ("value"));
			ccase.add_statement (new CCodeExpressionStatement (new CCodeAssignment (cfield, cgetcall)));
			ccase.add_statement (new CCodeBreakStatement ());
			cswitch.add_case (ccase);

			func_name = "%s_dup_func".printf (type_param.name.down ());
			enum_value = "%s_%s".printf (cl.get_lower_case_cname (null), func_name).up ();
			ccase = new CCodeCaseStatement (new CCodeIdentifier (enum_value));
			cfield = new CCodeMemberAccess.pointer (new CCodeMemberAccess.pointer (new CCodeIdentifier ("self"), "priv"), func_name);
			cgetcall = new CCodeFunctionCall (new CCodeIdentifier ("g_value_get_pointer"));
			cgetcall.add_argument (new CCodeIdentifier ("value"));
			ccase.add_statement (new CCodeExpressionStatement (new CCodeAssignment (cfield, cgetcall)));
			ccase.add_statement (new CCodeBreakStatement ());
			cswitch.add_case (ccase);

			func_name = "%s_destroy_func".printf (type_param.name.down ());
			enum_value = "%s_%s".printf (cl.get_lower_case_cname (null), func_name).up ();
			ccase = new CCodeCaseStatement (new CCodeIdentifier (enum_value));
			cfield = new CCodeMemberAccess.pointer (new CCodeMemberAccess.pointer (new CCodeIdentifier ("self"), "priv"), func_name);
			cgetcall = new CCodeFunctionCall (new CCodeIdentifier ("g_value_get_pointer"));
			cgetcall.add_argument (new CCodeIdentifier ("value"));
			ccase.add_statement (new CCodeExpressionStatement (new CCodeAssignment (cfield, cgetcall)));
			ccase.add_statement (new CCodeBreakStatement ());
			cswitch.add_case (ccase);
		}

		set_prop.block = block;
		
		codegen.source_type_member_definition.append (set_prop);
	}

	private CCodeStatement get_invalid_property_id_warn_statement () {
		// warn on invalid property id
		var cwarn = new CCodeFunctionCall (new CCodeIdentifier ("G_OBJECT_WARN_INVALID_PROPERTY_ID"));
		cwarn.add_argument (new CCodeIdentifier ("object"));
		cwarn.add_argument (new CCodeIdentifier ("property_id"));
		cwarn.add_argument (new CCodeIdentifier ("pspec"));
		return new CCodeExpressionStatement (cwarn);
	}

	void register_dbus_info () {
		var dbus = cl.get_attribute ("DBus");
		if (dbus == null) {
			return;
		}
		var dbus_iface_name = dbus.get_string ("name");
		if (dbus_iface_name == null) {
			return;
		}

		codegen.dbus_glib_h_needed = true;

		var dbus_methods = new StringBuilder ();
		dbus_methods.append ("{\n");

		var blob = new StringBuilder ();
		blob.append_c ('"');

		int method_count = 0;
		long blob_len = 0;
		foreach (Method m in cl.get_methods ()) {
			if (m is CreationMethod || m.binding != MemberBinding.INSTANCE) {
				continue;
			}

			dbus_methods.append ("{ (GCallback) ");
			dbus_methods.append (m.get_cname ());
			dbus_methods.append (", ");
			dbus_methods.append (codegen.get_marshaller_function (m.get_parameters (), m.return_type));
			dbus_methods.append (", ");
			dbus_methods.append (blob_len.to_string ());
			dbus_methods.append (" },\n");

			codegen.generate_marshaller (m.get_parameters (), m.return_type);

			long start = blob.len;

			blob.append (dbus_iface_name);
			blob.append ("\\0");
			start++;

			blob.append (m.name);
			blob.append ("\\0");
			start++;

			// synchronous
			blob.append ("S\\0");
			start++;

			foreach (FormalParameter param in m.get_parameters ()) {
				blob.append (param.name);
				blob.append ("\\0");
				start++;

				if (param.direction == ParameterDirection.IN) {
					blob.append ("I\\0");
					start++;
				} else if (param.direction == ParameterDirection.OUT) {
					blob.append ("O\\0");
					start++;
					blob.append ("F\\0");
					start++;
					blob.append ("N\\0");
					start++;
				} else {
					Report.error (param.source_reference, "unsupported parameter direction for D-Bus method");
				}

				blob.append (param.type_reference.get_type_signature ());
				blob.append ("\\0");
				start++;
			}

			if (!(m.return_type is VoidType)) {
				blob.append ("result\\0");
				start++;

				blob.append ("O\\0");
				start++;
				blob.append ("F\\0");
				start++;
				blob.append ("R\\0");
				start++;

				blob.append (m.return_type.get_type_signature ());
				blob.append ("\\0");
				start++;
			}

			blob.append ("\\0");
			start++;

			blob_len += blob.len - start;

			method_count++;
		}

		blob.append_c ('"');

		dbus_methods.append ("}\n");

		var dbus_signals = new StringBuilder ();
		dbus_signals.append_c ('"');
		foreach (Signal sig in cl.get_signals ()) {
			dbus_signals.append (dbus_iface_name);
			dbus_signals.append ("\\0");
			dbus_signals.append (sig.name);
			dbus_signals.append ("\\0");
		}
		dbus_signals.append_c('"');

		var dbus_methods_decl = new CCodeDeclaration ("const DBusGMethodInfo");
		dbus_methods_decl.modifiers = CCodeModifiers.STATIC;
		dbus_methods_decl.add_declarator (new CCodeVariableDeclarator.with_initializer ("%s_dbus_methods[]".printf (cl.get_lower_case_cname ()), new CCodeConstant (dbus_methods.str)));
		codegen.class_init_fragment.append (dbus_methods_decl);

		var dbus_object_info = new CCodeDeclaration ("const DBusGObjectInfo");
		dbus_object_info.modifiers = CCodeModifiers.STATIC;
		dbus_object_info.add_declarator (new CCodeVariableDeclarator.with_initializer ("%s_dbus_object_info".printf (cl.get_lower_case_cname ()), new CCodeConstant ("{ 0, %s_dbus_methods, %d, %s, %s, \"\\0\" }".printf (cl.get_lower_case_cname (), method_count, blob.str, dbus_signals.str))));
		codegen.class_init_fragment.append (dbus_object_info);

		var install_call = new CCodeFunctionCall (new CCodeIdentifier ("dbus_g_object_type_install_info"));
		install_call.add_argument (new CCodeIdentifier (cl.get_type_id ()));
		install_call.add_argument (new CCodeUnaryExpression (CCodeUnaryOperator.ADDRESS_OF, new CCodeIdentifier ("%s_dbus_object_info".printf (cl.get_lower_case_cname ()))));
		codegen.class_init_fragment.append (new CCodeExpressionStatement (install_call));
	}
}

