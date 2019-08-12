**FREE
       //DFTACTGRP(*NO) OPTION(*SRCSTMT: *NODEBUGIO)

       Ctl-Opt Option(*Srcstmt: *Nodebugio);

       Dcl-F SRVPGMMODE USAGE(*OUTPUT);

     /copy 'header/apipgmi'

      // API error code structure
     dcl-ds dsEC;
       dsECBytesP    Int(10) inz(%size(dsEC));
       dsECBytesA    Int(10) inz(0);
       dsECMsgID     Char(7);
       dsECReserv    Char(1);
       dsECMsgDta    Char(240);
     end-ds;

      //
      //  List API generic header structure
      //
     dcl-s p_Header    pointer;

     dcl-ds dsLH    BASED(p_Header);
      //  Filler
       dsLHFill1     char(103);
      //  Status (I=Incomplete,C=Complete
       dsLHStatus    char(1);
       dsLHFill2     char(12);
       dsLHHdrOff    int(10);
       dsLHHdrSiz    int(10);
       dsLHLstOff    int(10);
       dsLHLstSiz    int(10);
       dsLHEntCnt    int(10);
       dsLHEntSiz    int(10);
     end-ds;
      //
      // PGML0100 format: modules in program
      // SPGL0100 format: modules in service program
      // (these fields are the same in both APIs)
     dcl-s p_Entry    Pointer;

     dcl-ds dsPgm       based(p_Entry);
       dsPgm_Pgm       Char(10);
       dsPgm_PgmLib    Char(10);
       dsPgm_Module    Char(10);
       dsPgm_ModLib    Char(10);
       dsPgm_SrcF      Char(10);
       dsPgm_SrcLib    Char(10);
       dsPgm_SrcMbr    Char(10);
       dsPgm_Attrib    Char(10);
       dsPgm_CrtDat    Char(13);
       dsPgm_SrcDat    Char(13);
     end-ds;

     // reformat parms
     Dcl-DS inputParms;
       SearchThis       Char(20);
        ST_Library      Char(10) Overlay(SearchThis:1);
        ST_Module       Char(10) Overlay(SearchThis:11);
     End-DS;

     // reformat returned service program
     Dcl-DS returnedData;
       ReturnThis       Char(20);
        RT_PgmLib       Char(10) Overlay(ReturnThis:1);
        RT_Pgm          Char(10) Overlay(ReturnThis:11);
     End-DS;

      //  Global Field Definitions.

     dcl-s Objectlibrary  Char(20);
     dcl-s Entry          int(10);

      // DSPSRVPGM DETAIL()
      //
      //  Single Values
      //  *ALL
      // Other Values
      //  *BASIC       *tbd
      //  *SIZE
      //  *MODULE      *yes
      //  *SRVPGM
      //  *PROCEXP     *tbd
      //  *DTAEXP
      //  *ACTGRPEXP
      //  *ACTGRPIMP
      //  *SIGNATURE
      //  *COPYRIGHT

     dcl-PR Main ExtPgm('RtvSrvPgm');
        SearchModule     Char(10) OPTIONS(*NOPASS) CONST;
        Searchlibrary    Char(10) OPTIONS(*NOPASS) CONST;
     end-PR;

     dcl-PI main;
        SearchModule     Char(10) OPTIONS(*NOPASS) CONST;
        Searchlibrary    Char(10) OPTIONS(*NOPASS) CONST;
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

       // skip this section
       if 1 = 2;
       objectLibrary = '*ALL      ' + searchlibrary;

       //
       // List all ILE programs modules to space
       // List ILE Program Information (QBNLPGMI) API
       // https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/apis/qbnlpgmi.htm
       //

         QBNLPGMI( 'MODULES   QTEMP'
                 : 'PGML0200'
               : objectLibrary
               : dsEC
               );

       if dsECBytesA > 0;
         EC_Escape( 'Calling QBNLPGMI API'
                  : 3
                  : dsEC
                  );
       endif;

       // List occurrances of our module
       p_Entry = p_Header + dsLHLstOff;

       for Entry = 1 to dsLHEntCnt;
         // if dsPgm_Module = peModule;

           Pgm_Pgm    = dsPgm_Pgm;
           Pgm_PgmLib = dsPgm_PgmLib;
           Pgm_Module = dsPgm_Module;
           Pgm_ModLib = dsPgm_ModLib;
           Pgm_SrcF   = dsPgm_SrcF;
           Pgm_SrcLib = dsPgm_SrcLib;
           Pgm_SrcMbr = dsPgm_SrcMbr;
           Pgm_Attrib = dsPgm_Attrib;
           Pgm_CrtDat = dsPgm_CrtDat;
           Pgm_SrcDat = dsPgm_SrcDat;

           write srvpgmModR;

         // endif;
         p_Entry = p_Entry + dsLHEntSiz;
       endfor;
       // end of sipped section
       endif;

       // List all ILE service program modules to space
       QBNLSPGM( 'MODULES   QTEMP'
               : 'SPGL0100'
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

           Pgm_Pgm    = dsPgm_Pgm;
           Pgm_PgmLib = dsPgm_PgmLib;
           Pgm_Module = dsPgm_Module;
           Pgm_ModLib = dsPgm_ModLib;
           Pgm_SrcF   = dsPgm_SrcF;
           Pgm_SrcLib = dsPgm_SrcLib;
           Pgm_SrcMbr = dsPgm_SrcMbr;
           Pgm_Attrib = dsPgm_Attrib;
           Pgm_CrtDat = dsPgm_CrtDat;
           Pgm_SrcDat = dsPgm_SrcDat;
         // select by parms 1 and/or 2,  default to all

         If %parms = 2;
           // Format parms for compare
           ST_Library = Searchlibrary;
           ST_Module  = SearchModule;
           // Format data for compare
           RT_Pgm    = dsPgm_Pgm;
           RT_PgmLib = dsPgm_PgmLib;
           //  parms passed equal;
           if SearchThis = ReturnThis;
             write srvpgmModR;
           EndIf;

           Else;
             write srvpgmModR;
         EndIf;

         p_Entry = p_Entry + dsLHEntSiz;
       endfor;

      // And that's about the size of it
     *inlr = *on;

      // Send back an escape message based on an API error code DS
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
