package tina

when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib {"system:Winmm.lib", "system:Gdi32.lib", "system:Setupapi.lib", "system:Ole32.lib", "system:OleAut32.lib", "system:Version.lib", "system:User32.lib", "system:advapi32.lib", "system:Shell32.lib", "system:Imm32.lib", "windows/tina.lib", "windows/SDL2-static.lib"}
}
tina_func :: proc "c" (coro: ^tina, value: rawptr) -> rawptr
tina :: struct {
	body:           tina_func,
	user_data:      rawptr,
	name:           cstring,
	buffer:         rawptr,
	size:           uint,
	completed:      bool,
	_caller:        ^tina,
	_stack_pointer: rawptr,
	_canary_end:    ^u32,
	_canary:        u32,
}

@(default_calling_convention = "c", link_prefix = "tina_")
foreign lib {
	init :: proc(buffer: rawptr, size: uint, body: tina_func, user_data: rawptr) -> ^tina ---
	resume :: proc(coro: ^tina, value: rawptr) -> rawptr ---
	yield :: proc(coro: ^tina, value: rawptr) -> rawptr ---
	swap :: proc(from, to: ^tina, value: rawptr) -> rawptr ---
}
