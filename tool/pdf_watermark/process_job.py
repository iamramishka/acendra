"""Private pipe protocol for a trusted backend; never expose as a web endpoint."""
import base64
import json
import sys
from supervisor import generate_isolated

def main():
    try:
        raw=sys.stdin.buffer.read(72*1024*1024+1)
        if len(raw)>72*1024*1024: raise ValueError()
        job=json.loads(raw)
        if set(job)!={'source','identity'}: raise ValueError()
        source=base64.b64decode(job['source'],validate=True)
        result=generate_isolated(source,job['identity'])
        sys.stdout.buffer.write(result)
    except Exception:
        # No child tracebacks, names, paths or source bytes in operational logs.
        sys.stderr.write('PDF_GENERATION_FAILED\n')
        return 1
    return 0

if __name__=='__main__': sys.exit(main())
