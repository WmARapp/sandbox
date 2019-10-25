**FREE

     Dcl-s Rpt_ID         Packed(7:0) Inz(*Zeros);
     Dcl-s Rpt_Type       Char( 10)   Inz(*Blanks);
     Dcl-s Rpt_Rmk        Char(255)   Inz(*Blanks);
     Dcl-s File_In        SQLTYPE(BLOB_FILE);

     // The SQLTYPE(BLOB_FILE) definition will be converted by the compiler
     // into the following data structure: Errors will be thrown during compile

     // D File_In         DS
     // D File_In_NL                   10U 0
     // D File_In_DL                   10U 0
     // D File_In_FO                   10U 0
     // D File_In_NAME                255A

     // Store an object into the blob table

       Rpt_ID       = 1;
       Rpt_Type     = 'PDF';
       Rpt_Rmk      = 'Just a PDF test report';
       File_In_FO   = SQFRD;
       File_In_NAME = '/Reports/Test.PDF';
       File_In_NL   = %len(%trimr(File_In_NAME));

       EXEC SQL   Insert Into RptArchive/Reports
                         Values (:Rpt_ID, :Rpt_Type, NOW(),
                                :Rpt_Rmk , :File_In);

       *InLr = *On;
     /END-FREE


      * Now, let's retrieve the file from the archive, with the BLOB_OUT sample program:

     D Rpt_ID         S             7 0 Inz(*Zeros)
     D File_Out       s                   SQLTYPE(BLOB_FILE)

     * The SQLTYPE(BLOB_FILE) definition will be converted by the compiler
     * into the following data structure:

     D*File_Out       DS
     D*File_Out_NL                   10U 0
     D*File_Out_DL                   10U 0
     D*File_Out_FO                   10U 0
     D*File_Out_NAME               255A

     // Retrieve an object from the blob table

     /FREE
       Rpt_ID = 1;
       File_Out_FO   = SQFOVR;
       File_Out_NAME = '/Reports/Test_Out.PDF';
       File_Out_NL   = %Len(%TrimR(File_Out_NAME));
       EXEC SQL   Select Rpt_File1
                   Into :File_Out
                   From RptArchive/Reports
                   Where Rpt_Id = :Rpt_Id;

       *InLr = *On;

     /END-FREE
