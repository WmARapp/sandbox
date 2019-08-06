
#-------------------------------------------------------------------------------------------
# --- Libraries ----------------------------------------------- Edit for this Project ------
#-------------------------------------------------------------------------------------------

# library for programs
#BINLIB=WSCLIB
BINLIB=BRAPP

# library for data
#FILELIB=WSCFIL
FILELIB=BRAPP

#-------------------------------------------------------------------------------------------
# --- Standard variables ------------------------------------------- Do Not Change ---------
#-------------------------------------------------------------------------------------------

# shell to use (for consistency)
SHELL=/QOpenSys/usr/bin/qsh

# Compile option for easy debugging
DBGVIEW=*SOURCE


# get your user name in all caps
USER_UPPER := $(shell echo $(USER) | tr a-z A-Z)

# If your user name is in the path, we're assuming this is not 
# going to build in the main libraries
ifeq ($(USER_UPPER), $(findstring $(USER_UPPER),$(CURDIR)))
# so override the BINLIB and FILELIB in binlib.inc in your home directory
    include  ~/binlib.inc
endif


#-------------------------------------------------------------------------------------------
# --- Project Specific  ---------------------------------------- Edit for this Project ------
#-------------------------------------------------------------------------------------------


# your library list for rpg compiles
LIBLIST= VALENCE52 $(FILELIB) $(BINLIB) WSCLIB WSCFIL CMSFIL


# list of objects for your binding directory
BNDDIRLIST = getmodules.entrymod

# everything you want to build here
all: getmodules.rpgmod getmodules.pgm


# dependency lists
getmodules.pgm: getmodules.bnddir getmodules.rpgle
getsrvpgm.pgm: getsrvpgm.bnddir getsrvpgm.rpgle
	#
	getmodules.rpgmod: source/getmodules.rpgle
getsrvpgm.rpgmod: source/getsrvpgm.rpgle

getmodules.bnddir: $(BNDDIRLIST)

#empoccchg.sqlobj: source/empoccchg.sql 
#empoccchg.sqlobj: source/empoccchg.sql 
#uclxref.sqlobj: source/uclxref.sql
#return_employee_occupation_description.sqlobj: source/return_employee_occupation_description.sql


#-------------------------------------------------------------------------------------------
# --- Standard Build Rules ------------------------------------- Do Not Change -------------
#-------------------------------------------------------------------------------------------


%.bnddir:
	-system -q "CRTBNDDIR BNDDIR($(BINLIB)/$*)"
	-system -q "ADDBNDDIRE BNDDIR($(BINLIB)/$*) OBJ($(patsubst %.entrymod,(*LIBL/% *MODULE *IMMED),$^)))"
	@touch $^
	@touch $@


# sql statements should build in the data library
%.sqlobj:
	sed 's/FILELIB/$(FILELIB)/g' ./source/$*.sql  > ./source/$*.sql2
	system -q "RUNSQLSTM SRCSTMF('./source/$*.sql2')"
	rm ./source/$*.sql2
	@touch $@

%.rpgmod:
	liblist -a $(LIBLIST);\
	system "CRTSQLRPGI OBJ($(BINLIB)/$*) SRCSTMF('./$<') \
	COMMIT(*NONE) OBJTYPE(*MODULE) OPTION(*EVENTF) REPLACE(*YES) DBGVIEW($(DBGVIEW)) \
	compileopt('INCDIR(''$(CURDIR)''   ''/wright-service-corp/Utility'')')" 
	@touch $@


%.cnxpgm:
	liblist -a $(LIBLIST);\
	system "CRTSQLRPGI OBJ($(BINLIB)/$*) SRCSTMF('./source/$*.sqlrpgle') \
	COMMIT(*NONE) OBJTYPE(*PGM) OPTION(*EVENTF) REPLACE(*YES) DBGVIEW($(DBGVIEW)) \
	RPGPPOPT(*LVL2) \
	compileopt('INCDIR(''$(CURDIR)''   ''/wright-service-corp/Utility'')')"; 
	@touch $@

%.rpgle:
	liblist -a $(LIBLIST);\
	system "CRTRPGMOD MODULE($(BINLIB)/$*) SRCSTMF('./source/$*.rpgle') DBGVIEW($(DBGVIEW)) REPLACE(*YES)" 
	@touch $@


%.pgm:
	liblist -a $(LIBLIST);\
	system "CRTPGM PGM($(BINLIB)/$*)  BNDDIR($(BINLIB)/$*) REPLACE(*YES)"
	@touch $@

%.clle: 
	-system -q "CRTSRCPF FILE($(BINLIB)/QCLLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./source/$*.clle') TOMBR('/QSYS.lib/$(BINLIB).lib/QCLLESRC.file/$*.mbr') MBROPT(*replace)"
	liblist -a $(LIBLIST); system "CRTBNDCL PGM($(BINLIB)/$*) SRCFILE($(BINLIB)/QCLLESRC)"
	@touch $@

%.srvpgm:
    # We need the binder source as a member! SRCSTMF on CRTSRVPGM not available on all releases.
	-system -q "CRTSRCPF FILE($(BINLIB)/QSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./header/$*.bndsrc') TOMBR('/QSYS.lib/$(BINLIB).lib/QSRC.file/$*.mbr') MBROPT(*replace)"

	system "CRTSRVPGM SRVPGM($(BINLIB)/$*) MODULE($(patsubst %,$(BINLIB)/%,$(basename $^))) SRCFILE($(BINLIB)/QSRC)"
	@touch $@


%.entry:
    # Basically do nothing..
	@echo ""
	
%.entrymod:
    # Basically do nothing..
	@echo ""
	
%.entrysrv:
    # Basically do nothing..
	@echo ""
	
%.sqlrpgle:
    # Basically do nothing..
	@echo ""	