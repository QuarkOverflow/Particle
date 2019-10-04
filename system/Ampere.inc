format binary as 'aex'

Modifiers = 0

Modifier.public                         =    1
Modifier.private                        =    2
Modifier.protected                      =    4
; //                                    =    8
Modifier.final                          =    16
Modifier.static                         =    32
Modifier.abstract                       =    64
; //                                    =    128
Modifier.interface                      =    256

Revision = 0

macro $Revision value*& {
	if Revision < value
	    Revision = value
	end if
}

$Revision 0

macro Value value*, bits:32 {
	repeat bits / 4
		local nibble
        nibble = value shr (bits - %*4) and 0xF
		if nibble > 9
		    nibble = nibble + 'A' - 10
		else
		    nibble = nibble + '0'
		end if
		Display nibble
	end repeat
}

Entry equ

macro $Entry name*& {
	Entry equ name
}

macro Modifier mName*, notPermited& {
	macro mName info*& \{
		if (Modifiers and Modifier.\#mName) <> 0
			Display 10, 'Repetition of modifiers are not allowed.', 10
			Err
		end if
		irp name, notPermited \\{
			if (Modifiers and Modifier.\\#mName) <> 0
				Display 10, 'Combination of ', \\`mName, ' and ', \\`mName, ' mofifiers are not permited.', 10
				Err
			end if
		\\}
		Modifiers = Modifiers or Modifier.\#mName
		info
	\}
}

Modifier public, private, protected
Modifier private, public, protected
Modifier protected, public, private
Modifier final, static
Modifier static, final
Modifier abstract, interface
Modifier interface, abstract

macro class cInfo*& {
	match cName cExtension, cInfo \{
		cName\#.Modifiers = Modifiers
		Modifiers         = 0
		
		cName\#.Methods.length         = 0
		cName\#.Variables.length       = 0
		cName\#.FinalVariables.length  = 0
		cName\#.StaticVariables.length = 0
		cName\#.AbstractMethods.length = 0
		
		ClassBuffer equ cName
		super.\#cName equ Object
		
		sizeof.\#cName = 0
		
		match =extends super.cName sExtension, cExtension \\{ super.\\#cName equ super.cName \\}
		
		macro _\#cName
	\}
}

macro Mkstr sInfo*& {
	match sName == sValue, sInfo \{
		StringBuffer equ sName
		sName\#.String equ sValue
	\}
}

macro Int N {
	db    0xCD, N
}

postpone {
	@Signature                          dd    'ePiI'
	@Revision                           dd    Revision
	if ~ Entry eq
		@Entry                          dq    Entry
	else
		@Entry                          dq    ?
	end if
	@DynamicSize                        dq    EndOfFile
	irpv cName, ClassBuffer \{ Class cName \}
	irpv sName, StringBuffer \{
		if ~definite sName
			sName db sName\#.String, 0
			Align 8
		end if \}
	EndOfFile:
}

macro Class cName* {
	
	macro Field name, fDescriptor \{
		macro name fInfo*& \\{
			match fName fExtension, fInfo \\\{
				cName\\\#.\\\#fName\\\#.Modifiers = Modifiers
				Modifiers                         = 0
				
				match == vExtension, fExtension \\\\{
					cName\\\\#.\\\\#fName\\\\#.Value = vExtension
					cName\\\\#.Variables equ fName
				\\\\}
				match =( mExtension, fExtension \\\\{
					cName\\\\#.Methods equ fName
					
					macro _\\\\#cName\\\\#.\\\\#fName
				\\\\}
			\\\}
		\\}
	\}
	
	irpv name, ClassBuffer \{
		Field name, 'P'
	\}
	Field void   , 'V'
	Field boolean, 'Z'
	Field byte   , 'B'
	Field char   , 'C'
	Field int    , 'I'
	Field short  , 'S'
	Field long   , 'L'
	Field double , 'D'
	
	match super.cName, super.#cName \{
		;sizeof.\#cName = sizeof.\#super.cName
		cName\#.Variables.length       = super.cName\#.Variables.length
		cName\#.FinalVariables.length  = super.cName\#.FinalVariables.length
		cName\#.AbstractMethods.length = super.cName\#.AbstractMethods.length
		
		Display 10, \`cName, ' <- ', \`super.cName, 10
		
		irpv super.vName, super.cName\#.Variables \\{
			cName\\#.Variables equ super.vName
			if definite super.cName\\#.\\#super.vName
				cName\\#.\\#super.vName          = super.cName\\#.\\#super.vName
			end if
			cName\\#.\\#super.vName\\#.Pointer   = super.cName\\#.\\#super.vName\\#.Pointer
			cName\\#.\\#super.vName\\#.Modifiers = super.cName\\#.\\#super.vName\\#.Modifiers
		\\}
		irpv super.mName, super.cName\#.Methods \\{
			cName\\#.InheritedMethods equ super.mName
			cName\\#.\\#super.mName\\#.Pointer   = super.cName\\#.\\#super.mName\\#.Pointer
			cName\\#.\\#super.mName\\#.Modifiers = super.cName\\#.\\#super.mName\\#.Modifiers
			macro _\\#cName\\#.\\#super.mName \\\{
				_\\#super.cName\\#.\\#super.mName
			\\\}
		\\}
	\}
	
	cName#:
	_#cName
	
	match super.cName, super.#cName \{
		irpv vName, cName#.Variables \\{
			Variables vName, cName, super.cName
		\\}
		
		irpv mName, cName\#.Methods \\{
			Method mName, cName, super.cName
		\\}
		if cName\#.AbstractMethods.length
			cName\#.aMethodsTable:
		end if
		irpv super.mName, super.cName\#.Methods \\{
			if ~cName eq Object
				if definite super.cName\\#.\\#super.mName\\#.Address & ~definite cName\\#.\\#super.mName\\#.Address
					cName\\#.\\#super.mName\\#.Pointer = super.cName\\#.\\#super.mName\\#.Pointer
					cName\\#.\\#super.mName\\#.Address dq super.cName\\#.\\#super.mName
				else if ~definite cName\\#.\\#super.mName & ~super.cName\\#.\\#super.mName\\#.Modifiers and Modifier.abstract
					cName\\#.\\#super.mName              = super.cName\\#.\\#super.mName
					cName\\#.\\#super.mName\\#.Modifiers = super.cName\\#.\\#super.mName\\#.Modifiers
				else
					cName\\#.\\#super.mName\\#.Pointer = super.cName\\#.\\#super.mName\\#.Pointer
					cName\\#.\\#super.mName\\#.Address dq cName\\#.\\#super.mName
				end if
			end if
		\\}
		irpv super.mName, cName\#.InheritedMethods \\{
			cName\\#.Methods equ super.mName
		\\}
		
	\}
	
	if cName#.AbstractMethods.length
		cName#.abstractMethods = sizeof.#cName * 8
		sizeof.#cName          = sizeof.#cName + 1
	end if
	
	irpv vName, cName#.Variables \{
		if ~definite cName\#.\#vName & cName\#.\#vName\#.Modifiers and Modifier.static
			cName\#.\#vName dq cName\#.\#vName\#.Value
		end if
		if ~cName\#.\#vName\#.Modifiers and Modifier.final & ~cName\#.\#vName\#.Modifiers and Modifier.static
			cName\#.\#vName = sizeof.\#cName * 8
			sizeof.\#cName  = sizeof.\#cName + 1
		end if
	\}
	
	Display `cName, ' : '
	Value sizeof.#cName
	Display 10
}

macro Variables vName*, cName*, super.cName {
	if ~definite super.cName#.#vName#.Pointer | cName eq Object
		if ~cName#.#vName#.Modifiers and Modifier.abstract
			if cName#.#vName#.Modifiers and Modifier.final
				cName#.#vName dq cName#.#vName#.Value
				cName#.#vName#.Pointer       = cName#.FinalVariables.length * 8
				cName#.FinalVariables.length = cName#.FinalVariables.length + 1
			else if cName#.#vName#.Modifiers and Modifier.static
				cName#.#vName#.Pointer        = cName#.StaticVariables.length * 8
				cName#.StaticVariables.length = cName#.StaticVariables.length + 1
			else
				cName#.#vName#.Pointer  = cName#.Variables.length * 8
				cName#.Variables.length = cName#.Variables.length + 1
			end if
		else
			Display 10, 'Variable ', `vName, ' in class ', `cName, ' contains modifier "abstract" and this is not allowed.', 10
			Err
		end if
	end if
}

macro Method mName*, cName*, super.cName* {
	cName#.#mName#.Variables.length = 0
	
	macro Variable vType*, vDescriptor* \{
		macro vType [vInfo*] \\{
			match vName, vInfo \\\{
				.\\\#Variables.length = .\\\#Variables.length - 1
				.\\\#vName            = .\\\#Variables.length * 8
			\\\}
		\\}
	\}
	
	macro Get dest*, src*, size \{
		if defined cName\#.\#mName\#.\#src
			mov    dest, size[rbp+cName\#.\#mName\#.\#src]
		else if defined super.cName\#.\#src\#.Pointer & ~cName eq Object
			if ~super.cName\#.\#src\#.Modifiers and Modifier.private
				if super.cName\#.\#src\#.Modifiers and Modifier.final | super.cName\#.\#src\#.Modifiers and Modifier.static
					mov    dest, size[cName\#.\#src]
				else 
					mov    dest, size[rbx+cName\#.\#src]
				end if
			else
				Display 10, 'Variable ', \`super.cName, '.', \`src, ' is private and cannot be accessed.', 10
				Err
			end if
		else if defined cName\#.\#src
			if cName\#.\#src\#.Modifiers and Modifier.final | cName\#.\#src\#.Modifiers and Modifier.static
				mov    dest, size[cName\#.\#src]
			else
				mov    dest, size[rbx+cName\#.\#src]
			end if
		else if defined src
			if ~src\#.Modifiers and Modifier.private
				if src\#.Modifiers and Modifier.final | src\#.Modifiers and Modifier.static
					mov    dest, size[src]
				else
					mov    dest, size[rbx+src]
				end if
			else
				Display 10, 'Variable ', \`src, ' is private and cannot be accessed.', 10
				Err
			end if
		else
			Display 10, 'Variable ', \`src, ' not defined.', 10
			Assert 0
		end if
	\}
	
	macro Set dest*, src*, size \{
		if defined cName\#.\#mName\#.\#dest
			mov    size[rbp+cName\#.\#mName\#.\#dest], src
		else if defined super.cName\#.\#dest\#.Pointer & ~cName eq Object
			if ~super.cName\#.\#dest\#.Modifiers and Modifier.private
				if super.cName\#.\#dest\#.Modifiers and Modifier.final | super.cName\#.\#dest\#.Modifiers and Modifier.static
					mov    size[cName\#.\#dest], src
				else 
					mov    size[rbx+cName\#.\#dest], src
				end if
			else
				Display 10, 'Variable ', \`super.cName, '.', \`dest, ' is private and cannot be accessed.', 10
				Err
			end if
		else if defined cName\#.\#dest
			if cName\#.\#dest\#.Modifiers and Modifier.final | cName\#.\#dest\#.Modifiers and Modifier.static
				mov    size[cName\#.\#dest], src
			else
				mov    size[rbx+cName\#.\#dest], src
			end if
		else if defined dest
			if ~dest\#.Modifiers and Modifier.private
				if dest\#.Modifiers and Modifier.final | src\#.Modifiers and Modifier.static
					mov    size[dest], src
				else
					mov    size[rbx+dest], src
				end if
			else
				Display 10, 'Variable ', \`dest, ' is private and cannot be accessed.', 10
				Err
			end if
		else
			Display 10, 'Variable ', \`dest, ' not defined.', 10
			Assert 0
		end if
	\}
	
	macro Mak opc*, dest*, src*, size \{
		if defined .\#dest
			mov    size[rbp+.\#dest], src
		else if defined super.cName\#.\#dest\#.Pointer & ~cName eq Object
			if ~super.cName\#.\#dest\#.Modifiers and Modifier.private
				if super.cName\#.\#dest\#.Modifiers and Modifier.final | super.cName\#.\#dest\#.Modifiers and Modifier.static
					opc    size[cName\#.\#dest], src
				else 
					opc    size[rbx+cName\#.\#dest], src
				end if
			else
				Display 10, 'Variable ', \`super.cName, '.', \`dest, ' is private and cannot be accessed.', 10
				Err
			end if
		else if defined cName\#.\#dest
			if cName\#.\#dest\#.Modifiers and Modifier.final | cName\#.\#dest\#.Modifiers and Modifier.static
				opc    size[cName\#.\#dest], src
			else
				opc    size[rbx+cName\#.\#dest], src
			end if
		else if defined dest
			if ~dest\#.Modifiers and Modifier.private
				if dest\#.Modifiers and Modifier.final | src\#.Modifiers and Modifier.static
					opc    size[dest], src
				else
					opc    size[rbx+dest], src
				end if
			else
				Display 10, 'Variable ', \`dest, ' is private and cannot be accessed.', 10
				Err
			end if
		else
			Display 10, 'Variable ', \`dest, ' not defined.', 10
			Assert 0
		end if
	\}
	
	macro Call name* \{
		if defined super.cName\#.\#name\#.Pointer & ~cName eq Object
			if ~super.cName\#.\#name\#.Modifiers and Modifier.private | super.cName\#.\#name\#.Modifiers and Modifier.abstract
				if super.cName\#.\#name\#.Modifiers and Modifier.abstract
					mov    rax, [rbx   ]
					mov    rax, [rax+  cName\#.\#name]
					call   rax
				else
					call   cName\#.\#name
				end if
			else
				Display 10, 'Method ', \`super.cName, '.', \`name, ' is private and cannot be accessed.', 10
				Err
			end if
		else if defined cName\#.\#name
			if cName\#.\#name\#.Modifiers and Modifier.abstract
				mov    rax, [rbx   ]
				mov    rax, [rax+  cName\#.\#name]
				call   rax
			else
				call   cName\#.\#name
			end if
		else if defined name
			if ~name\#.Modifiers and Modifier.private
				if name\#.Modifiers and Modifier.abstract
					mov    rax, [rbx   ]
					mov    rax, [rax+  name]
					call   rax
				else
					call   name
				end if
			else
				Display 10, 'Method ', \`name, ' is private and cannot be accessed.', 10
				Err
			end if
		else
			Display 10, 'Method ', \`name, ' not defined.', 10
			Assert 0
		end if
	\}
	
	macro new name*, vName:0 \{
		if ~name\#.Modifiers and Modifier.abstract & ~name\#.Modifiers and Modifier.interface
			mov    rax, [@DynamicSize]
			if ~ vName eq 0
				Set vName, rax
			end if
			mov    rbx, rax
			add    rax, sizeof.\#name * 8
			mov    [@DynamicSize], rax
		else
		end if
	\}
	
	macro Prologue \{
		push   rbp
		mov    rbp, rsp
		if .\#Variables.length
			if (.\#Variables.length mod 2)
				sub    rsp, (-.\#Variables.length + 0) * 8
			else
				sub    rsp, (-.\#Variables.length + 1) * 8
			end if
		end if
	\}
	
	macro return \{
		leave
		ret
	\}
	
	macro Halt \{
		cli
		hlt
	\}
	
	irpv name, ClassBuffer \{
		Variable name, 'P'
	\}
	Variable boolean, 'Z'
	Variable byte   , 'B'
	Variable char   , 'C'
	Variable int    , 'I'
	Variable short  , 'S'
	Variable long   , 'L'
	Variable double , 'D'
	
	if ~definite super.cName#.#mName | cName eq Object
		if cName#.#mName#.Modifiers and Modifier.abstract
			if cName#.Modifiers and Modifier.abstract | cName#.Modifiers and Modifier.interface
				cName#.#mName#.Pointer        = cName#.AbstractMethods.length * 8
				cName#.AbstractMethods.length = cName#.AbstractMethods.length + 1
			else
				Display 10, 'Abstract method ', `mName, ' in class ', `cName, ' must be declared inside abstract classes or interfaces.', 10
				Err
			end if
		else if ~definite cName#.#mName
			if cName#.Modifiers and Modifier.interface
				Display 10, 'Method ', `mName, ' in inrerface ', `cName, ' must be declared abstract.', 10
				Err
			end if
			if ~cName#.#mName#.Modifiers and Modifier.final
				cName#.#mName#.Pointer = cName#.Methods.length * 8
				cName#.Methods.length  = cName#.Methods.length + 1
			end if
			USE64
			cName#.#mName#:
			_#cName#.#mName
		end if
	else
		if ~super.cName#.#mName#.Modifiers and Modifier.final
			if cName#.#mName#.Modifiers = super.cName#.#mName#.Modifiers
				USE64
				cName#.#mName#:
				_#cName#.#mName
			else
				Display 10, 'Method ', `mName, ' must contain the same modifiers as in class ', `super.cName, '.', 10
				Err
			end if
		else
			Display 10, 'Method ', `mName, ' in class ', `super.cName, ' is final and thus can be overrided.', 10
			Err
		end if
	end if
	Align 8
	
	irpv name, ClassBuffer \{
		Purge name
	\}
	Purge boolean, byte, char, int, short, long, double
	
}

public class Object:
{
	
}

















































