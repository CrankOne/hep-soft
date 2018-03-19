# Software environment for HEP

The purpose of this repository is to provide robust and modern environment for
analysis and simulation task of High-Energy Physics (HEP). It is quite common
effort (see, e.g. [FairSoft](https://github.com/FairRootGroup/FairSoft)),
however we are aiming a slightly different priorities:
   1. Tracking new versions of front-end software (like Geant4 or CERN ROOT) as
      fast as possible.
   2. Fully deterministic environment (1).

"Fully deterministic" means that one have to maintain the
linux-from-scratch system providing the building procedures for every package
installed in it. Many of the software components used in modern HEP require
quite expensive dependencies such as Qt, making this activity unaffordable for
individual researches.

We hope, however, that involving a specialized tool may make this task feasible
for collaborative group of interested scientific programmers and system
administrators.

(1) This is a long-term goal that will remain unreached for, may be, couple of
years, depending on community support.

