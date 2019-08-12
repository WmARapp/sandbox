
       Dcl-PR EC_Escape;
         Whenx           Char(60)     const;
         CallStackCnt    Int(10)      value;
         ErrorCode       Char(32766)  options(*varsize);
       End-pr;

       // List ILE program information API
       Dcl-PR QBNLPGMI    ExtPgm('QBNLPGMI');
         UsrSpc     Char(20)     const;
         Format     Char(8)      const;
         PgmName    Char(20)     const;
         Errors     Char(32766)  options(*varsize);
       End-pr;

       // List ILE service program information API
       Dcl-PR QBNLSPGM    ExtPgm('QBNLSPGM');
         UsrSpc    Char(20)     const;
         Format    Char(8)      const;
         SrvPgm    Char(20)     const;
         Errors    Char(32766)  options(*varsize);
       End-pr;

       // Create User Space API
       Dcl-Pr QUSCRTUS    ExtPgm('QUSCRTUS');
         UsrSpc       Char(20)     const;
         ExtAttr      Char(10)     const;
         InitSize     Int(10)      const;
         InitVal      Char(1)      const;
         PublicAuth   Char(10)     const;
         Text         Char(50)     const;
         Replace      Char(10)     const;
         Errors       Char(32766)  options(*varsize);
       End-pr;

       // Retrieve pointer to user space API
       Dcl-PR QUSPTRUS    ExtPgm('QUSPTRUS');
         UsrSpc     Char(20)   const;
         Pointer    pointer;
       End-pr;
