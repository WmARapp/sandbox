#
#                              --- version 1.5 ----
#
#-------------------------------------------------------------------------------------------
# --- Libraries ----------------------------------------------- Edit for this Project ------
#-------------------------------------------------------------------------------------------

# library for programs
BINLIB=WSCLIB

# library for data
FILELIB=WSCFIL

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

#Let's avoid duplicate libraries
ifeq ($(FILELIB), $(BINLIB))
    ADDLIBS=$(FILELIB)
else
    ADDLIBS=$(FILELIB) $(BINLIB)
endif

#path for source
VPATH = source:header

#-------------------------------------------------------------------------------------------
# --- Project Specific  ---------------------------------------- Edit for this Project ------
#-------------------------------------------------------------------------------------------


# your library list for rpg compiles
LIBLIST= VALENCE52  CMSFIL  WSCFIL WSCLIB $(ADDLIBS)


# everything you want to build here
all: rtvsrvpgmw.pgm 
#


# dependency lists

rtvsrvpgmw.pgm: rtvsrvpgm.bnddir rtvsrvpgmw.sqlrpgmod

# list of objects for your binding directory
rtvsrvpgm.bnddir: BNDDIRLIST = rtvsrvpgmw.entrymod


#-------------------------------------------------------------------------------------------
# --- Standard Build Rules ------------------------------------- Do Not Change -------------
#-------------------------------------------------------------------------------------------



%.bnddir:
	-system -q "CRTBNDDIR BNDDIR($(BINLIB)/$*)"
	-system -q "ADDBNDDIRE BNDDIR($(BINLIB)/$*) OBJ($(patsubst %.entrysrv,(*LIBL/% *SRVPGM *IMMED), $(patsubst %.entrymod,(*LIBL/% *MODULE *IMMED),$(BNDDIRLIST))))"
	@touch $*.bnddir


# sql statements should build in the data library
%.sqlobj: %.sql
	sed 's/FILELIB/$(FILELIB)/g' ./source/$*.sql  > ./source/$*.sql2
	system -q "RUNSQLSTM SRCSTMF('./source/$*.sql2')"
	rm ./source/$*.sql2
	@touch $@


%.sqlrpgmod: %.sqlrpgle
	-liblist -a $(LIBLIST);
	system "CRTSQLRPGI OBJ($(BINLIB)/$*) SRCSTMF('./source/$*.sqlrpgle') \
	COMMIT(*NONE) OBJTYPE(*MODULE) OPTION(*EVENTF) REPLACE(*YES) DBGVIEW($(DBGVIEW)) \
	compileopt('INCDIR(''$(CURDIR)''   ''/wright-service-corp/Utility'')')" 
	@touch $@


%.cnxpgm:
	-liblist -a $(LIBLIST);
	system "CRTSQLRPGI OBJ($(BINLIB)/$*) SRCSTMF('./source/$*.sqlrpgle') \
	COMMIT(*NONE) OBJTYPE(*PGM) OPTION(*EVENTF) REPLACE(*YES) DBGVIEW($(DBGVIEW)) \
	RPGPPOPT(*LVL2) \
	compileopt('INCDIR(''$(CURDIR)''   ''/wright-service-corp/Utility'')')"; 
	@touch $@


%.cnxmod: %.sqlrpgle
	-liblist -a $(LIBLIST);
	-system "CRTSQLRPGI OBJ($(BINLIB)/$*) SRCSTMF('./source/$*.sqlrpgle') \
	COMMIT(*NONE) OBJTYPE(*MODULE) OPTION(*EVENTF) REPLACE(*YES) DBGVIEW($(DBGVIEW)) \
	RPGPPOPT(*LVL2) \
	compileopt('INCDIR(''$(CURDIR)''   ''/wright-service-corp/Utility'')')"; 
	@touch $@	


%.rpglemod: %.rpgle
	-liblist -a $(LIBLIST);
	system "CRTRPGMOD MODULE($(BINLIB)/$*) SRCSTMF('./source/$*.rpgle') DBGVIEW($(DBGVIEW)) REPLACE(*YES)" 
	@touch $@


%.rpglepgm: %.rpgle
	-liblist -a $(LIBLIST);
	system "CRTBNDRPG PGM($(BINLIB)/$*) SRCSTMF('./source/$*.rpgle') \
	OPTION(*EVENTF) DBGVIEW(*SOURCE) REPLACE(*YES) \
	INCDIR('$(CURDIR)'   '/wright-service-corp/Utility')";
	@touch $@


%.pgm:
	-liblist -a $(LIBLIST);
	system "CRTPGM PGM($(BINLIB)/$*)  BNDDIR($(BINLIB)/$*) REPLACE(*YES)"
	@touch $@


%.cllebndpgm:  %.clle
	-system -q "CRTSRCPF FILE($(BINLIB)/QCLLESRC) RCDLEN(92)"
	system "CPYFRMSTMF FROMSTMF('./source/$*.clle') TOMBR('/QSYS.lib/$(BINLIB).lib/QCLLESRC.file/$*.mbr') MBROPT(*replace)"
	system "CHGPFM FILE($(BINLIB)/QCLLESRC) MBR($*) SRCTYPE(CLLE)"
	-liblist -a $(LIBLIST); 
	system "CRTBNDCL PGM($(BINLIB)/$*) SRCFILE($(BINLIB)/QCLLESRC)"
	@touch $@


%.cllemod: %.clle
	-system -q "CRTSRCPF FILE($(BINLIB)/QCLLESRC) RCDLEN(92)"
	system "CPYFRMSTMF FROMSTMF('./source/$*.clle') TOMBR('/QSYS.lib/$(BINLIB).lib/QCLLESRC.file/$*.mbr') MBROPT(*replace)"
	system "CHGPFM FILE($(BINLIB)/QCLLESRC) MBR($*) SRCTYPE(CLLE)"
	-liblist -a $(LIBLIST);
	system "CRTCLMOD MODULE($(BINLIB)/$*) SRCFILE($(BINLIB)/QCLLESRC) SRCMBR($*) OPTION(*EVENTF) REPLACE(*YES) DBGVIEW(*SOURCE)"


%.prtfile: %.prtf
	-system -q "CRTSRCPF FILE($(BINLIB)/QDDSSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./source/$*.prtf') TOMBR('/QSYS.lib/$(BINLIB).lib/QDDSSRC.file/$*.mbr') MBROPT(*replace)"
	system "CHGPFM FILE($(BINLIB)/QCLLESRC) MBR($*) SRCTYPE(PRTF)"
	system "CRTPRTF FILE($(BINLIB)/$*) SRCFILE($(BINLIB)/QDDSSRC) SRCMBR($*)"
	@touch $@


%.srvpgm:
    # We need the binder source as a member! Also requires a bindir SRCSTMF on CRTSRVPGM not available on all releases.
	-system -q "CRTSRCPF FILE($(BINLIB)/QSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./header/$*.bndsrc') TOMBR('/QSYS.lib/$(BINLIB).lib/QSRC.file/$*.mbr') MBROPT(*replace)"
	system "CHGPFM FILE($(BINLIB)/QCLLESRC) MBR($*) SRCTYPE(BND)"
	-liblist -a $(LIBLIST);\
	system "CRTSRVPGM SRVPGM($(BINLIB)/$*) BNDDIR($(BINLIB)/$*) SRCFILE($(BINLIB)/QSRC)"
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
