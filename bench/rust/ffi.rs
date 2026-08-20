pub type MallocFn = unsafe extern "C" fn(size: usize, alignment: usize) -> *mut std::ffi::c_void;

static HOOK: std::sync::OnceLock<MallocFn> = std::sync::OnceLock::new();

pub struct BenchAllocator;

unsafe impl std::alloc::GlobalAlloc for BenchAllocator {
    #[inline]
    unsafe fn alloc(&self, layout: std::alloc::Layout) -> *mut u8 {
        let malloc = HOOK.get().expect("set_malloc() was not called");
        (malloc)(layout.size(), layout.align()) as *mut u8
    }

    #[inline]
    unsafe fn dealloc(&self, _ptr: *mut u8, _layout: std::alloc::Layout) {
        // no-op
    }
}

#[global_allocator]
static GLOBAL: BenchAllocator = BenchAllocator;

#[no_mangle]
pub unsafe extern "C" fn set_malloc(malloc_fn: MallocFn) {
    HOOK.set(malloc_fn)
        .expect("set_malloc() called more than once");
}

#[repr(C)]
pub struct Header {
    pub width: u32,
    pub height: u32,
}

#[no_mangle]
pub unsafe extern "C" fn decode_qoi_rust(
    bytes: *const u8,
    len: usize,
    hdr: *mut Header,
) -> *mut u8 {
    let input = std::slice::from_raw_parts(bytes, len);
    let (header, mut pixels) = qoi_rust::decode_to_vec(input).unwrap();
    (*hdr).width = header.width;
    (*hdr).height = header.height;
    pixels.as_mut_ptr()
}

#[no_mangle]
pub unsafe extern "C" fn decode_rapid_qoi(
    bytes: *const u8,
    len: usize,
    hdr: *mut Header,
) -> *mut u8 {
    let input = std::slice::from_raw_parts(bytes, len);
    let (header, mut pixels) = rapid_qoi::Qoi::decode_alloc(input).unwrap();
    (*hdr).width = header.width;
    (*hdr).height = header.height;
    pixels.as_mut_ptr()
}
