import subprocess
import sys

def generateSignature(elf='my.elf', dumpfile='my.memdump.bin', sigfile='my.sig'):
    begsig_cmd = "riscv32-unknown-elf-nm {} | grep begin_signature | cut -d' ' -f1".format(elf)
    endsig_cmd = "riscv32-unknown-elf-nm {} | grep end_signature | cut -d' ' -f1".format(elf)
    datamem_offset_cmd = "riscv32-unknown-elf-nm {} | grep custom_datamem_offset | cut -d' ' -f1".format(elf)

    begsig_addr = subprocess.run(begsig_cmd, stdout=subprocess.PIPE, shell=True).stdout.decode('utf-8')
    endsig_addr = subprocess.run(endsig_cmd, stdout=subprocess.PIPE, shell=True).stdout.decode('utf-8')
    datamem_offset_addr = subprocess.run(datamem_offset_cmd, stdout=subprocess.PIPE, shell=True).stdout.decode('utf-8')

    begsig_addr = int(begsig_addr, 16) 
    endsig_addr = int(endsig_addr, 16)
    datamem_offset_addr = int(datamem_offset_addr, 16)

    with open(dumpfile, mode='rb') as dumpfile:
        dump_content = dumpfile.read()
        sig = dump_content[begsig_addr - datamem_offset_addr:endsig_addr - datamem_offset_addr]
        # assume that sig have size as multiple of 4 bytes
        with open(sigfile, mode='w') as sigfile:
            for i in range(0, len(sig), 4):
                sigfile.write(sig[i:i+4][::-1].hex() + '\n')

generateSignature(sys.argv[1], sys.argv[2], sys.argv[3])
