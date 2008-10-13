/*
    Copyright 2002-2008 Tampere University of Technology.  All Rights
    Reserved.

    This file is part of TTA-Based Codesign Environment (TCE).

    TCE is free software; you can redistribute it and/or modify it under the
    terms of the GNU General Public License version 2 as published by the Free
    Software Foundation.

    TCE is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
    details.

    You should have received a copy of the GNU General Public License along
    with TCE; if not, write to the Free Software Foundation, Inc., 51 Franklin
    St, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, you may use this file as part of a free software
    library without restriction.  Specifically, if other files instantiate
    templates or use macros or inline functions from this file, or you compile
    this file and link it with other files to produce an executable, this
    file does not by itself cause the resulting executable to be covered by
    the GNU General Public License.  This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/
/**
 * @file TCEAsmPrinter.h
 * 
 * Declaration of TCEAsmPrinter class.
 * 
 * @author Veli-Pekka Jääskeläinen 2007 (vjaaskel-no.spam-cs.tut.fi)
 * @note rating: red
 */

#include <llvm/CodeGen/AsmPrinter.h>

#include <map>

namespace llvm {
class TCEAsmPrinter : public AsmPrinter {
 public:
    TCEAsmPrinter(
        llvm::raw_ostream& o, TargetMachine& tm, const TargetAsmInfo* t);


   virtual ~TCEAsmPrinter();

   virtual const char* getPassName() const {
      return "TCE Assembly Printer";
   }

 private:
   void printOperand(const MachineInstr *MI, int opNum);
   void printMemOperand(
       const MachineInstr *MI, int opNum, const char *Modifier = 0);

   void printCCOperand(const MachineInstr *MI, int opNum);

   bool printInstruction(const MachineInstr *MI);  // autogenerated.
   bool runOnMachineFunction(MachineFunction &F);

   bool doInitialization(Module &M);
   bool doFinalization(Module &M);
   bool PrintAsmOperand(
       const MachineInstr* mi, unsigned opNo,
       unsigned asmVariant, const char* extraCode);

   typedef std::map<const Value*, unsigned> ValueMapTy;
   ValueMapTy NumberForBB_;
};
}
