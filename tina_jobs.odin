package tina


when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib {"system:Winmm.lib", "system:Gdi32.lib", "system:Setupapi.lib", "system:Ole32.lib", "system:OleAut32.lib", "system:Version.lib", "system:User32.lib", "system:advapi32.lib", "system:Shell32.lib", "system:Imm32.lib", "windows/tina.lib", "windows/SDL2-static.lib"}
}

Job :: struct {}
Scheduler :: struct {}

RunMode :: enum {
	Loop, // Run jobs from a queue until tina_scheduler_interrupt() is
	// called.
	Flush, // Run jobs from a queue until empty, or until all remaing
	// jobs are waiting.
	Single, // Run a single non-waiting job from a queue.
}

Group :: struct {
	// Private:
	_job_list: ^Job,
	_count:    uint,
}

_tina_fiber_factory :: proc(
	sched: ^Scheduler,
	fiber_idx: uint,
	buffer: rawptr,
	stack_size: uint,
	user_ptr: rawptr,
) -> ^tina

JobFunc :: proc "c" (job: ^Job)

JobDescription :: struct {
	// Job name. (optional)
	name:      cstring,
	// Job body function.
	func:      JobFunc,
	// User defined job context pointer. (optional)
	user_data: rawptr,
	// User defined job index. (optional, useful for parallel-for constructs)
	user_idx:  uintptr,
	// Index of the queue to run the job on.
	queue_idx: uint,
}

@(default_calling_convention = "c", link_prefix = "tina_")
foreign lib {
	job_get_scheduler :: proc(job: ^Job) -> ^Scheduler ---
	job_get_description :: proc(job: ^Job) -> ^JobDescription ---
	scheduler_size :: proc(job_count: uint, queue_count: uint, fiber_count: uint, stack_size: uint) -> uint ---
	scheduler_init :: proc(buffer: rawptr, job_count: uint, queue_count: uint, fiber_count: uint, stack_size: uint) -> ^Scheduler ---
	scheduler_init_ex :: proc(buffer: rawptr, job_count: uint, queue_count: uint, fiber_count: uint, stack_size: uint, fiber_factory: ^_tina_fiber_factory, fiber_data: rawptr) -> ^Scheduler ---
	scheduler_destroy :: proc(sched: ^Scheduler) ---
	scheduler_new :: proc(job_count: uint, queue_count: uint, fiber_count: uint, stack_size: uint) -> ^Scheduler ---
	scheduler_free :: proc(sched: ^Scheduler) ---
	scheduler_queue_priority :: proc(sched: ^Scheduler, queue_idx: uint, fallback_idx: uint) ---
	scheduler_run :: proc(sched: ^Scheduler, queue_idx: uint, mode: RunMode) -> bool ---
	scheduler_interrupt :: proc(sched: ^Scheduler, queue_idx: uint) ---
	scheduler_enqueue_batch :: proc(sched: ^Scheduler, list: [^]JobDescription, count: uint, group: ^Group, max_group_count: uint) -> uint ---
	scheduler_enqueue_n :: proc(sched: ^Scheduler, func: JobFunc, user_data: rawptr, count: uint, queue_idx: uint, group: ^Group) ---
	job_wait :: proc(job: ^Job, group: ^Group, threshold: uint) -> uint ---
	job_yield :: proc(job: ^Job) ---
	job_switch_queue :: proc(job: ^Job, queue_idx: uint) -> uint ---
	group_increment :: proc(sched: ^Scheduler, group: ^Group, count: uint, max_count: uint) -> uint ---
	group_decrement :: proc(sched: ^Scheduler, group: ^Group, count: uint) ---
}

scheduler_enqueue :: #force_inline proc "c" (
	sched: ^Scheduler,
	func: JobFunc,
	user_data: rawptr,
	user_idx: uintptr,
	queue_idx: uint,
	group: ^Group,
) {
	desc: JobDescription = {
		name      = nil,
		func      = func,
		user_data = user_data,
		user_idx  = user_idx,
		queue_idx = queue_idx,
	}
	scheduler_enqueue_batch(sched, &desc, 1, group, 0)
}
