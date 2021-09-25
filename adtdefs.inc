&ifndef adtdefs__inc
&define adtdefs__inc

{ This is an include file included in every module of PascalAdt
  library. It is not a unit, because it contains $define directives,
  which do not work outside the unit they were defined with FPC. With
  Delphi they do not work either way, so you have to set the defines
  manually at the compiler level. See the note below the description
  of the defines. }

{ PascalAdt library files recognise the following defines (or the lack
  of them): }
{ INLINE_DIRECTIVE - the compiler supports inlining }
{ INLINE_DIRECTIVE_REPEAT - defined if the inline directive must be
  repeated in the implementation of a routine }
{ OVERLOAD_DIRECTIVE - the compiler supports overloading with an
  'overload' directive in the routine declaration (not fully
  implemented, dropped in newer versions) }
{ WIDE_CHARACTERS - the compiler supports wide characters (WideChar)
  and wide strings (WideString) }
{ BLOCK_SIZE_STORED_BEFORE - the size of a heap block is stored
  adtBlockSizeDistance bytes before the returned address of the block }
{ DEBUG_PASCAL_ADT, _DEBUG, DEBUG - compiling in the debug mode; many
  assertions will be generated, plus some additional sanity checks }
{ TEST_PASCAL_ADT - compiling in the library test mode; some features
  for debugging the library itself are turned on, including the
  logging facilities; may slow the program down considerably }
{ MEMORY_TRACING - turns on memory tracing; enabled by default in the
  debug and the library test modes }
{ STRINGS_UNIT - defined if the Strings unit for handling PChar's should be
  included in a uses clause in addition to the SysUtils unit }
{ AT_REQUIRED - defined if the @ operator is required before a routine to take
  its address }
{ PASCAL_ADT_WINDOWS - compiling for the windows operating system; off
  by default; not strictly necessary to enable this to compile the
  library for this system; used mainly by the logging facilities }
{ DELPHI - compiling with some version of Delphi (set in this include
  file automatically) }

{ Most of the above defines are set automatically. However, if you use a Delphi
  compiler you will have to set these defines manually at the compiler level.
  The minimum workable set is: OVERLOAD_DIRECTIVE;WIDE_CHARACTERS;DELPHI
  For debugging use: PASCAL_ADT_DEBUG
  For memory tracing: MEMORY_TRACING;BLOCK_SIZE_STORED_BEFORE
  For testing the library: TEST_PASCAL_ADT + the defines for debugging and
  memory tracing }


{ turn off range checking (won't work with dynamic buffers) }
{$R-}

{ -------------------- defines for Free Pascal Compiler ----------------------- }
{$ifdef FPC }

{$inline on }

{$ifdef VER2 }
{$define INLINE_DIRECTIVE_ALSO_BUGGY }
{$define INLINE_DIRECTIVE_REPEAT_ALSO_BUGGY }
{$define INLINE_ACROSS_MODULES_ALSO_BUGGY }
{$define INLINE_DIRECTIVE_IN_INTERFACE_ALSO_BUGGY }
{$endif }
{ note: in versions 1 and 2 inlining is buggy and works only under certain
  circumstances, so it's better not to enable it }
{$define OVERLOAD_DIRECTIVE }
{$define BLOCK_SIZE_STORED_BEFORE }
{$define STRINGS_UNIT }
{$define AT_REQUIRED }

{$endif FPC }


{ ---------------------- defines for Virtual Pascal --------------------------- }
{ Virtual Pascal support has been dropped in the early stages of the
  development of the library because it lacks too many features. }
{$ifdef VPASCAL }

{$define INLINE_DIRECTIVE }
{$define INLINE_DIRECTIVE_IN_INTERFACE }

{$endif VPASCAL }


{ ---------------------- defines for Delphi versions -------------------------- }

{ The following conditional defines are present for Delphi verisons: }
{ VER80 (Delphi 1.x), VER90 (Delphi 2.x), VER100 (Delphi 3.x), VER120
  (Delphi 4.x), VER130 (Delphi 5.x), VER140 (Delphi 6.x). Note: VERxx
  means the version mentioned or a newer one. }
{ Some features of each version: }
{     http://delphi.about.com/cs/azindex/a/dhistory_2.htm }
{ Delphi 4 - dynamic arrays, overloading }
{ Delphi 5 - default parameters }
{ Delphi 6 - $if directive }

{ ---------------------------- Delphi 4 or higher ----------------------------  }
{$ifdef VER120 }

{$define OVERLOAD_DIRECTIVE }
{$define WIDE_CHARACTERS }
{$define DELPHI }

{$endif VER120 }


{ -----------  defines/switches for debugging and testing -------------------  }
{ PascalAdt library is compiled in debug mode if one of the the
  following is globally defined: DEBUG, _DEBUG or DEBUG_PASCAL_ADT. In
  debug mode all assertions are on, as well as some additional checks
  on validity of input data (there are in fact a lot of checks). }
{ PascalAdt library is compiled in test mode if TEST_PASCAL_ADT is
  defined. In this mode all features of debug mode are on and some
  additional information about the structures themselves is written to
  log file (adttest.log). This mode is mainly for testing the library
  itself. }

{$ifdef DEBUG }
{$define DEBUG_PASCAL_ADT }
{$endif }

{$ifdef _DEBUG }
{$define DEBUG_PASCAL_ADT }
{$endif }

{$ifdef TEST_PASCAL_ADT }
{$define DEBUG_PASCAL_ADT }
{$define MEMORY_TRACING }
{$endif }

{$ifdef DEBUG_PASCAL_ADT }
{ turn on assertions }
{$C+}
{$endif }

{ @discard-recent-comments }

type
   { @header Type definitions. @until-next-comment }
   { Basic type definitions used within PascalAdt library.  }
   { PointerValueType and UnsignedType should be unsigned; SizeType
     may be signed or not; IndexType must be signed. IndexType must be
     signed because it is used as a return type when calculating
     distances and also in order to allow constructs like: for i :=
     container.LowIndex to container.HighIndex do ...  when container
     is empty and indices are zero-based (HighIndex returns -1, which
     must be less than LowIndex). If SizeType is unsigned then you
     should be careful when comparing it with IndexType. By default it
     is signed, although it is not an error to make it unsigned.  }
   { Even if SizeType is unsigned only positive values are stored in
     it }
   { CharType should be a type into which any character type can be
     casted without the loss of information }
   { SizeOf(PointerValueType) must be equal to
     SizeOf(Pointer). IndexType must be signed and of at least the
     size of PointerValueType. SizeType may be signed or unsigned, but
     must be of at least the size of IndexType. UnsignedType must be
     unsigned and of at least the size of SizeType.  }
   PointerValueType = PtrUInt;
   UnsignedType = PtrUInt;
   SizeType = PtrInt;
   IndexType = PtrInt;
{$ifdef WIDE_CHARACTERS }
   CharType = WideChar;
{$else }
   CharType = Char;
{$endif WIDE_CHARACTERS }

   PPointerValueType = ^PointerValueType;
   PUnsignedType = ^UnsignedType;
   PSizeType = ^SizeType;
   PIndexType = ^IndexType;
   PCharType = ^CharType;

   PPointer = ^Pointer;
   PByte = ^Byte;

{ @header Constants. }
const
   adtUnlimitedArrayIndex = 1;
   adtBitsInByte = 8;

&# macro definitions

&ifndef KeyType
   &define KeyType 1
&endif

&ifdef MCP_NO_MULTITHREADING
   &define threadvar var
&endif

&# arg1 - type to dispose
&macro _mcp_default_disposer
   nil
&endm

&# arg1 - type of items
&macro _mcp_hasher
   &if (&arg1& == String)
      AnsiStringHasher
   &elseif (&arg1& == Integer || &arg1& == Cardinal)
      IntegerHasher
   &elseif (&arg1& == Real)
      RealHasher
   &else
      nil
   &endif
&endm

&# arg1 - type of items
&macro _mcp_comparer
   nil
&endm

&macro _mcp_substractable
   &if (&ItemType == Real || &ItemType == Integer || &ItemType == Cardinal)
      _MCP_TRUE
   &endif
&endm

&# arg1, arg2 - arguments to subtract
&macro _mcp_diff
   &if (&_mcp_substractable)
      &arg2& - &arg1&
   &else &# not meaningful
      DefaultItem
   &endif
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 - the name of the variable to assign
&# arg4 - type of the arguments
&# arg5 - name of the external comparer
&macro _mcp_compare_assign_aux
   if (&arg5& <> nil) then
   begin
      &arg3& := &arg5&.Compare(&arg1&, &arg2&);
   end else
   begin
   &if (&arg4& == String)
      &arg3& := CompareStr(&arg1&, &arg2&);
   &elseif (&arg4& == Integer || &arg4& == Cardinal || &arg4& == Real)
      &arg3& := &arg1& - &arg2&;
   &else
      &arg3& := &arg5&.Compare(&arg1&, &arg2&);
   &endif
   end;
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 - the name of the variable to assign
&# arg4 (optional) - the name of the comparer to use; defaults to ItemComparer
&macro _mcp_compare_assign
   &ifdef arg4
      &_mcp_compare_assign_aux(&arg1&, &arg2&, &arg3&, &ItemType&, &arg4&)
   &else
      &_mcp_compare_assign_aux(&arg1&, &arg2&, &arg3&, &ItemType&, ItemComparer)
   &endif
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 - comparison operator (<, >, =, ...)
&# arg4 (optional) - the name of the comparer; defaults to ItemComparer
&macro _mcp_compare
   &ifndef arg4
      &local-define arg4 ItemComparer
   &endif
   (((&arg4& = nil) and (
   &if (&ItemType == String)
      CompareStr(&arg1&, &arg2&) &arg3& 0
   &elseif (&ItemType == Integer || &ItemType == Cardinal || &ItemType == Real)
      &arg1& &arg3& &arg2&
   &else
      &arg4&.Compare(&arg1&, &arg2&) &arg3& 0
   &endif
   )) or ((&arg4& <> nil) and (&arg4&.Compare(&arg1&, &arg2&) &arg3& 0)))
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 (optional) - the name of the comparer; defaults to ItemComparer
&macro _mcp_lt
   &ifdef arg3
      &_mcp_compare(&arg1&, &arg2&, < , &arg3&)
   &else
      &_mcp_compare(&arg1&, &arg2&, < )
   &endif
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 (optional) - the name of the comparer; defaults to ItemComparer
&macro _mcp_gt
   &ifdef arg3
      &_mcp_compare(&arg1&, &arg2&, > , &arg3&)
   &else
      &_mcp_compare(&arg1&, &arg2&, > )
   &endif
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 (optional) - the name of the comparer; defaults to ItemComparer
&macro _mcp_lte
   &ifdef arg3
      &_mcp_compare(&arg1&, &arg2&, <= , &arg3&)
   &else
      &_mcp_compare(&arg1&, &arg2&, <= )
   &endif
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 (optional) - the name of the comparer; defaults to ItemComparer
&macro _mcp_gte
   &ifdef arg3
      &_mcp_compare(&arg1&, &arg2&, >= , &arg3&)
   &else
      &_mcp_compare(&arg1&, &arg2&, >= )
   &endif
&endm

&# arg1, arg2 - arguments to compare;
&# arg3 (optional) - the name of the comparer; defaults to ItemComparer
&macro _mcp_equal
   &ifdef arg3
      &_mcp_compare(&arg1&, &arg2&, = , &arg3&)
   &else
      &_mcp_compare(&arg1&, &arg2&, = )
   &endif
&endm

&# arg1 - the name of the file to &include
&macro _mcp_generic_include
   &expand-non-prefixed-on
   &ifdef MCP_SRCDOC
      &define _mcp_prefix __prefix__
      &define ItemType ItemType
      &include &arg1&
   &else
      &define _mcp_prefix
      &define ItemType TObject
      &include &arg1&

      &define _mcp_prefix String
      &define ItemType String
      &include &arg1&

      &ifdef MCP_POINTER
         &define _mcp_prefix Pointer
         &define ItemType Pointer
         &include &arg1&
      &endif

      &ifdef MCP_INTEGER
         &define _mcp_prefix Integer
         &define ItemType Integer
         &include &arg1&
      &endif

      &ifdef MCP_CARDINAL
         &define _mcp_prefix Cardinal
         &define ItemType Cardinal
         &include &arg1&
      &endif

      &ifdef MCP_REAL
         &define _mcp_prefix Real
         &define ItemType Real
         &include &arg1&
      &endif
   &endif &# end not MCP_SRCDOC
   &expand-non-prefixed-off
&endm &# end _mcp_generic_include

&macro _mcp_map_generic_include
   &expand-non-prefixed-on
   &ifdef MCP_SRCDOC
      &define _mcp_map_prefix __map_prefix__
      &define _mcp_key_prefix __key_prefix__
      &define _mcp_item_prefix __item_prefix__
      &define ItemType ItemType
      &define KeyType KeyType
      &include &arg1&
   &else
      &define _mcp_map_prefix ObjectObject
      &define _mcp_item_prefix
      &define _mcp_key_prefix
      &define ItemType TObject
      &define KeyType TObject
      &include &arg1&

      &define _mcp_map_prefix
      &define _mcp_item_prefix
      &define _mcp_key_prefix String
      &define ItemType TObject
      &define KeyType String
      &include &arg1&

      &define _mcp_map_prefix StringString
      &define _mcp_item_prefix String
      &define _mcp_key_prefix String
      &define ItemType String
      &define KeyType String
      &include &arg1&

      &ifdef MCP_POINTER
         &define _mcp_map_prefix StringPointer
         &define _mcp_item_prefix Pointer
         &define _mcp_key_prefix String
         &define ItemType Pointer
         &define KeyType String
         &include &arg1&

         &define _mcp_map_prefix PointerPointer
         &define _mcp_item_prefix Pointer
         &define _mcp_key_prefix Pointer
         &define ItemType Pointer
         &define KeyType Pointer
         &include &arg1&
      &endif

      &ifdef MCP_INTEGER
         &define _mcp_map_prefix StringInteger
         &define _mcp_item_prefix Integer
         &define _mcp_key_prefix String
         &define ItemType Integer
         &define KeyType String
         &include &arg1&
      &endif

      &ifdef MCP_CARDINAL
         &define _mcp_map_prefix StringCardinal
         &define _mcp_item_prefix Cardinal
         &define _mcp_key_prefix String
         &define ItemType Cardinal
         &define KeyType String
         &include &arg1&
      &endif

      &ifdef MCP_REAL
         &define _mcp_map_prefix StringReal
         &define _mcp_item_prefix Real
         &define _mcp_key_prefix String
         &define ItemType Real
         &define KeyType String
         &include &arg1&
      &endif
   &endif
   &expand-non-prefixed-off
&endm &# end _mcp_map_generic_include

&# arg1 - type name
&macro _mcp_default_instance
   &if (&arg1 == Integer || &arg1 == Cardinal || &arg1 == Real)
      0
   &elseif (&arg1 == String)
      ''
   &else
      nil
   &endif
&endm

&macro DefaultItem
   &_mcp_default_instance(&ItemType&)
&endm

&macro DefaultKey
   &_mcp_default_instance(&KeyType&)
&endm

&macro _mcp_is_special_value
   &if (&ItemType == TObject || &ItemType == Pointer || &ItemType == String)
      _MCP_TRUE
   &else
      &NULL
   &endif
&endm

&macro _mcp_are_two_special_values
   &if (&ItemType == TObject || &ItemType == Pointer || &ItemType == String)
      _MCP_TRUE
   &else
      &NULL
   &endif
&endm

&macro _mcp_special_value
   &if (&ItemType == TObject || &ItemType == Pointer)
      nil
   &elseif (&ItemType == String)
      '&&*^%$#@!__MCP_SPECIAL_VALUE_FREE_PLACE__&&*^%$#@!'
   &endif
&endm

&macro _mcp_secondary_special_value
   &if (&ItemType == TObject)
      TObject(-1)
   &elseif (&ItemType == Pointer)
      Pointer(-1)
   &elseif (&ItemType == String)
      '&&*^%$#@!__MCP_SPECIAL_VALUE_DELETED_PALCE__&&*^%$#@!'
   &endif
&endm

&macro _mcp_accepts_nil
   &if (&ItemType == TObject || &ItemType == Pointer)
      _MCP_TRUE
   &else
      &NULL&
   &endif
&endm

&macro _mcp_inline
   &ifdef MCP_INLINE
      inline;
   &endif
&endm

&# arg1 - the type
&macro _mcp_type_needs_destruction
   &if (&arg1& == Integer || &arg1& == Cardinal || &arg1& == Real || &arg1& == String)
      &NULL&
   &else
      _MCP_TRUE
   &endif
&endm

&# arg1 - the thing to dispose; arg2 - the name of the operation to perform
&# arg3 - the name of the test indicating whether the item should be disposed
&# arg4 - the name of the disposer - is tested whether non-nil
&# arg5 - the type of the thing to dispose
&macro _mcp_dispose
   &if (&arg5& == TObject)
      if &arg3& then
      begin
         if &arg4& <> nil then
         begin
            if &arg1& <> nil then
               &arg4&.Perform(&arg1&)
         end else
            &arg1&.Free;
      end;
   &elseif (&arg5 == String || &arg5 == Integer || &arg5 == Real ||
               &arg5 == Cardinal)
      &# do nothing
   &else
      &arg2&(&arg1&);
   &endif
&endm

&macro _mcp_dispose_item
   _mcp_dispose(&arg1&, &arg2&, &arg3&, &arg4&, &ItemType&)
&endm

&macro _mcp_dispose_key
   _mcp_dispose(&arg1&, &arg2&, &arg3&, &arg4&, &KeyType&)
&endm

&macro DisposeItem
   &_mcp_dispose_item(&arg1&, &<DisposeItem>, OwnsItems, ItemDisposer)
&endm

&macro DisposeKey
   &_mcp_dispose_key(&arg1&, &<DisposeKey>, OwnsKeys, KeyDisposer)
&endm

&# we need this macro to set uninitialized variables (and only uninitialized!)
&# arg1 - the thing to set
&macro _mcp_set_zero
   FillByte(PByte(@&arg1&)^, SizeOf(&arg1&), 0);
&endm

&macro PItemType ^ItemType

&macro _mcp_address_of_DisposeItem
   &expand-non-prefixed-off
   {$ifdef AT_REQUIRED}@{$endif}DisposeItem
   &expand-non-prefixed-on
&endm

&endif &# end include guard
