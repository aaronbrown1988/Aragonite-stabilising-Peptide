use LAMMPS::Datafile;
use LAMMPS::AtomType;
use LAMMPS::Atom;


$test = new LAMMPS::Datafile;
$test->read_data("/home/brown/sandbox/lmp_spc/out.lmp");
$test->write();
print $test->list_atoms;


