"""Trusted Linux process supervisor. Unsupported platforms fail before parsing."""
import multiprocessing
import os
import sys
import tempfile
from pathlib import Path
from watermark import generate, WatermarkError, Limits


def _child(source, output, kwargs, memory_bytes):
    import resource
    resource.setrlimit(resource.RLIMIT_AS, (memory_bytes,memory_bytes))
    resource.setrlimit(resource.RLIMIT_CPU, (60,60))
    resource.setrlimit(resource.RLIMIT_FSIZE, (50*1024*1024,50*1024*1024))
    resource.setrlimit(resource.RLIMIT_NOFILE, (32,32))
    resource.setrlimit(resource.RLIMIT_CORE, (0,0))
    resource.setrlimit(resource.RLIMIT_NPROC, (0,0))
    result=generate(source,**kwargs)
    Path(output).write_bytes(result)


def supervised_generate(source, *, wall_seconds=60, memory_bytes=512*1024*1024, **trusted_kwargs):
    """Called by a trusted non-root Linux backend. No CLI/client metadata intake.

    This bounds process resources, not filesystem/network authority. Deployment
    must additionally use an unprivileged worker in a network-denied sandbox.
    """
    if sys.platform!='linux' or os.name!='posix' or not hasattr(os,'getuid') or os.getuid()==0:
        raise WatermarkError('Hard-constrained non-root Linux runtime required')
    if type(wall_seconds) is not int or not 1<=wall_seconds<=60 or type(memory_bytes) is not int or not 64*1024*1024<=memory_bytes<=512*1024*1024:
        raise WatermarkError('Invalid process bounds')
    if type(source) is not bytes or not 0<len(source)<=50*1024*1024:
        raise WatermarkError('Input bound exceeded')
    # Reject configuration that broadens the runtime ceilings.
    limits=trusted_kwargs.get('limits',Limits())
    if not isinstance(limits,Limits) or limits.max_input_bytes>50*1024*1024 or limits.max_output_bytes>50*1024*1024 or limits.max_pages>500:
        raise WatermarkError('Worker ceiling exceeded')
    with tempfile.TemporaryDirectory(prefix='acedra-watermark-') as directory:
        output=str(Path(directory)/'derivative.pdf')
        process=multiprocessing.get_context('spawn').Process(target=_child,args=(source,output,trusted_kwargs,memory_bytes))
        process.start()
        try:
            process.join(wall_seconds)
            if process.is_alive():
                process.kill(); process.join()
                raise WatermarkError('Generation timed out')
            if process.exitcode!=0 or not Path(output).is_file():
                raise WatermarkError('Generation worker failed')
            if not 0<Path(output).stat().st_size<=50*1024*1024:
                raise WatermarkError('Output bound exceeded')
            return Path(output).read_bytes()
        finally:
            if process.is_alive(): process.kill(); process.join()
            process.close()


def generate_isolated(source, kwargs):
    """Fixed-ceiling API for the trusted durable queue adapter.

    kwargs accepts the same trusted metadata/font/limits as generate; it cannot
    override process constraints. Source never returned on worker failure.
    """
    if type(kwargs) is not dict or set(kwargs)-{'display_name','license_id','source_sha256','limits','trusted_font_path'}:
        raise WatermarkError('Invalid trusted job metadata')
    return supervised_generate(source,**kwargs)
