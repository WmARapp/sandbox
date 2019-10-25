**FREE

    Ctl-Opt Option(*Srcstmt: *Nodebugio);

    /copy 'header/apipgmi'
    /copy 'header/sqlerrhndl'


    // API error code structure
    dcl-ds dsEC;
      dsECBytesP     int(10) inz(%size(dsEC));
      dsECBytesA     int(10) inz(0);
      dsECMsgID      char(7);
      dsECReserv     char(1);
      dsECMsgDta     char(240);
    end-ds;

    //
    //  List API generic header structure
    //
    dcl-s p_Header    pointer;

    dcl-ds dsLH       based(p_Header);
    //  Filler
      dsLHFill1       char(103);
    //  Status (I=Incomplete,C=Complete
      dsLHStatus      char(1);
      dsLHFill2       char(12);
      dsLHHdrOff      int(10);
      dsLHHdrSiz      int(10);
      dsLHLstOff      int(10);
      dsLHLstSiz      int(10);
      dsLHEntCnt      int(10);
      dsLHEntSiz      int(10);
    end-ds;
    //
    // PGML0100 format: modules in program
    // SPGL0100 format: modules in service program
    // (these fields are the same in both APIs)
    dcl-s p_Entry     pointer;

    dcl-ds dsPgm      based(p_Entry);
      dsPgm_Pgm       char(10);
      dsPgm_PgmLib    char(10);
      dsPgm_Module    char(10);
      dsPgm_ModLib    char(10);
      dsPgm_SrcF      char(10);
      dsPgm_SrcLib    char(10);
      dsPgm_SrcMbr    char(10);
      dsPgm_Attrib    char(10);
      dsPgm_CrtDat    char(13);
      dsPgm_SrcDat    char(13);
    end-ds;

    // reformat parms
    Dcl-DS inputParms;
      SearchThis      char(20);
      ST_Library      char(10) Overlay(SearchThis:1);
      ST_Module       char(10) Overlay(SearchThis:11);
    End-DS;

    // reformat returned service program
    Dcl-DS returnedData;
      ReturnThis      char(20);
      RT_PgmLib       char(10) Overlay(ReturnThis:1);
      RT_Pgm          char(10) Overlay(ReturnThis:11);
    End-DS;

      //  Global Field Definitions.

     dcl-s Objectlibrary  char(20);
     dcl-s Entry          int(10);

     dcl-s formatName     char(10);
     // Format Nmae and usage based on cmd DSPSRVPGM
     // Single Values
     //  *ALL
     // Other Values
     //  *BASIC
     //  *SIZE
     //  *MODULE
     //  *SRVPGM
     //  *PROCEXP
     //  *DTAEXP
     //  *ACTGRPEXP
     //  *ACTGRPIMP
     //  *SIGNATURE
     //  *COPYRIGHT
     dcl-c FORMATSPGL0100 const('SPGL0100'); // module (*MODULE) information
     dcl-c FORMATSPGL0100 const('SPGL0110'); //
     dcl-c FORMATSPGL0100 const('SPGL0200'); // Service program (*SRVPGM) information
     dcl-c FORMATSPGL0100 const('SPGL0300'); // Data items exported to the activation group (*ACTGRPEXP)
     dcl-c FORMATSPGL0100 const('SPGL0400'); //
     dcl-c FORMATSPGL0100 const('SPGL0500'); //
     dcl-c FORMATSPGL0100 const('SPGL0600'); // Service program procedure export (*PROCEXP) information.
     dcl-c FORMATSPGL0100 const('SPGL0610'); //
     dcl-c FORMATSPGL0100 const('SPGL0700'); // Service program data export (*DTAEXP) information
     dcl-c FORMATSPGL0100 const('SPGL0800'); // Service program signature (*SIGNATURE) information

     dcl-s speachMark     char(1) inz('''');



     dcl-PR Main ExtPgm('RtvSrvPgm');
        SearchModule     char(10) OPTIONS(*NOPASS) CONST;
        Searchlibrary    char(10) OPTIONS(*NOPASS) CONST;
     end-PR;

     dcl-PI main;
        SearchModule     char(10) OPTIONS(*NOPASS) CONST;
        Searchlibrary    char(10) OPTIONS(*NOPASS) CONST;
     end-PI;

       // ALL program; service programs  with ADD

       // Create a user space to stuff module info into
       // Create User Space (QUSCRTUS) API
       // https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/apis/quscrtus.htm
       //
       QUSCRTUS( 'MODULES   QTEMP'
               : 'USRSPC'
               : 5120*3072
               : x'00'
               : '*ALL'
               : 'List of modules'
               : '*YES'
               : dsEC
               );

       if dsECBytesA > 0;
         EC_Escape( 'Calling QUSCRTUS API'
                  : 3
                  : dsEC
                  );
       endif;

       // Rtv Pointer to User Space
       // Retrieve Pointer to User Space (QUSPTRUS) API
       // https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/apis/qusptrus.htm
       //
       QUSPTRUS( 'MODULES   QTEMP'
               : p_Header
               );

       //
       // set formatName for List type
       // https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/qbnlspgm.htm
       //
       formatName = formatSPGL0100;

       // List all ILE service program modules to space
       QBNLSPGM( 'MODULES   QTEMP'
               : formatName
               : '*ALL      *ALLUSR'
               : dsEC
               );

       if dsECBytesA > 0;
         EC_Escape( 'Calling QBNLSPGM API'
                  : 3
                  : dsEC
                  );
       endif;

       // List occurrances of our module
       p_Entry = p_Header + dsLHLstOff;

       for Entry = 1 to dsLHEntCnt;

         // select by parms 1 and/or 2,  default to all

         if %parms = 2;
           // Format parms for compare
           ST_Library = Searchlibrary;
           ST_Module  = SearchModule;
           // Format data for compare
           RT_Pgm    = dsPgm_Pgm;
           RT_PgmLib = dsPgm_PgmLib;
           //  parms passed equal;
           if SearchThis = ReturnThis;
             //
             if insertRow();
               leave;
             endif;
           endIf;

         else;
           //
           if insertRow();
             leave;
           endif;
         endIf;

         p_Entry = p_Entry + dsLHEntSiz;
       endFor;

      //
     *inlr = *on;

      // Send an escape msg based on an API error code DS
     DCL-PROC EC_Escape ;

     Dcl-PI *N;
        Whenx           char(60)    const;
        CallStackCnt    int(10)     value;
        ErrorCode       char(32766) options(*varsize);
     End-PI;

      // Send Program Message API
     Dcl-Pr QMHSNDPM    ExtPgm('QMHSNDPM');
        MessageID     Char(7)   Const;
        QualMsgF      Char(20)  Const;
        MsgData       Char(256) Const;
        MsgDtaLen     Int(10)   Const;
        MsgType       Char(10)  Const;
        CallStkEnt    Char(10)  Const;
        CallStkCnt    Int(10)   Const;
        MessageKey    Char(4);
        Errors        Char(1);
     End-Pr;

      // API error code (passed from caller)
     Dcl-s p_EC    pointer;

     Dcl-Ds dsEC    based(p_EC);
       dsECBytesP    int(10);
       dsECBytesA    int(10);
       dsECMsgID     Char(7);
       dsECReserv    Char(1);
       dsECMsgDta    Char(240);
     End-Ds;

      // API error code (no error handling requested)
     Dcl-Ds dsNullError;
       dsNullError0    Int(10) inz(0);
     end-ds;

     dcl-S MsgDtaLen    Int(10);
     dcl-S MsgKey       Char(4);


       p_EC = %addr(ErrorCode);
       if dsECBytesA <= 16;
         MsgDtaLen = 0;
       else;
         MsgDtaLen = dsECBytesA - 16;
       endif;

       // diagnostic msg tells us when the error occurred in our pgm
       QMHSNDPM( 'CPF9897'
               : 'QCPFMSG   *LIBL'
               :  Whenx
               : %Len(%trimr(whenx))
               : '*DIAG'
               : '*'
               : 1
               :  MsgKey
               : dsNullError
               );

       // send back actual error from API
       QMHSNDPM(dsECMsgID
               : 'QCPFMSG   *LIBL'
               : dsECMsgDta
               : MsgDtaLen
               : '*ESCAPE'
               : '*': CallStackCnt: MsgKey
               : dsNullError
               );

    End-Proc;

      // insert entries
     DCL-PROC insertRow ;

     Dcl-PI *N ind;

     End-PI;

       // local variables
       //

       dcl-s addedUser        varchar(18);
       dcl-s passfail ind inz(*off);

       // local constants
       //

       addedUser      = 'DB_ADMIN';

       Exec SQL
         insert into srvpgmmods
           (SRVPGMNAME, SRVPGMLIB,
            MODNAME, MODLIB,
            SRCFILE, SRCLIB, SRCNAME,
            MODATTR,
            MODCREATED,
            SRCUPDATED,
            ADDED_ON,
            ADDED_BY,
            UPDATED,
            UPD_USER
          )
         values(:dsPGM_Pgm, :dsPGM_PgmLib,
                :dsPGM_Module, :dsPGM_ModLib,
                :dsPGM_SrcF,
                :dsPGM_SrcLib,
                :dsPGM_SrcMbr,
                :dsPGM_Attrib,
                :dsPGM_CrtDat,
                :dsPGM_SrcDat,
                current timestamp, :addedUser, current timestamp, :addedUser
               );

      If xSQLState2 <> Success_On_SQL;
        passfail = *on;
      EndIf;

      return passfail;

    End-Proc;
