-- Copyright (c) 2015 Oracle
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- This SQL*Loader script is used to load data into the PRINT_MEDIA table and
-- its nested table column TEXTDOCS_NESTEDTAB. Normally a child table (i.e.,
-- a nested table column) can be loaded together with its parent table with a
-- single INTO TABLE clause.  However, there is a restriction in SQL*Loader
-- which prevents this in the case where the nested table contains a
-- a LOB column that is loaded from a separate file, which is the case we 
-- have here. A simple workaround to this restriction is to load the parent
-- and child tables separately with two INTO TABLE clauses.  
--
-- A parent table and any of its children tables are linked together by 
-- means of a set identifier (SID) column. In the parent table the
-- nested table column itself holds the SID to its corresponding rows in the
-- child table. In the child table each set of rows which correspond to a
-- single row in the parent table has the same SID in a hidden column. When
-- parent and child tables are loaded together with a single INTO TABLE
-- clause, the SIDs are automatically generated for the user.  When the two
-- tables are loaded separately with two INTO TABLE clauses, as they are in
-- this script, then it is necessary for the user to provide the SIDs within
-- the input data for both tables.  A SID is a 16 byte binary value that
-- should be unique in the database.  In this script, the SIDs are specified
-- as hexadecimal character strings.  SQL Loader will convert the hexadecimal
-- string into a 16 byte binary value.  The values used in the data file for
-- this example were generated by the SQL function SYS_GUID():
--   SELECT SYS_GUID() FROM DUAL;
-- 
-- Some comments about the input data/control file are in order here:
--
-- (1) The input data fields have been arranged such that they each
-- are terminated by a comma and may be enclosed by quotes.  This has been
-- done solely for readability purposes; there is no requirement that the
-- data be arranged in this fashion. In fact, if we were loading large amounts
-- of data, it would be better to use a different field layout since field
-- terminators and enclosures are a drain on performance. For this script
-- this is not a problem because we are only loading four rows into the
-- parent table and twelve rows into the child table.  If there is anything
-- that may affect performance, it will be the size of the LOBs that are
-- used.
--
-- (2) Because we are loading two tables we need a way to distinguish the
-- input records.  A one-byte filler field, table_typ,  has been added for
-- this purpose.  The "P" records are targetted for the print_media table
-- while the "T" records are targetted for the TEXTDOCS_NESTEDTAB table. Each
-- set of nested table records have been placed after its corresponding 
-- parent record. This also is not necessary but has been done for readability
-- purposes. Because the table_typ field tags each record they may be placed
-- in any order in the input data.
--
-- (3) The CONTINUEIF clause has been used for readability purposes. It allows
-- us to arrange the data so that it multiple physical records, which can fit
-- nicely within an 80-column record, can be grouped together into one large
-- logical record.  The press_release fields contain a moderate amount of
-- textual data and it is easier to read and modify if we can see it all on
-- one line.  Of course this is possible because we can control the format
-- of the input data. In cases where the input data is generated by some
-- application there may be little or no control over this format. The first
-- record in a set of physical records has a space in the first byte of the
-- record. All other physical records that form the single logical record
-- has a '+' in the first byte of the record. Notice that the use of a 
-- CONTINUEIF clause doesn't affect absolute positioning. That is, we have
-- used one byte for the continuation character but we pretend that this
-- character is not there when we use the POSITION keyword; we still start
-- the numbering at 1.
--
-- (4) The actual input data is not included within this script. This is
-- done to allow for a directory-independent way to call SQL*Loader
--
-- (5) The INTO TABLE clauses use the INSERT mode which requires that the 
-- target tables be empty before loading.  This is done to safeguard against
-- inadvertently losing data. If requirements change, then other modes such
-- as REPLACE or APPEND may be used by replaciing the INSERT keyword with
-- one of the aforementioned modes.
--

LOAD DATA
CONTINUEIF NEXT(1) = '+'

INTO TABLE print_media
INSERT
WHEN table_typ = 'P'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
(
 table_typ            FILLER POSITION(1)   CHAR,
 product_id           CHAR,
 ad_id                CHAR,
 ad_textdocs_ntab_sid FILLER CHAR,
 ad_textdocs_ntab     SID (ad_textdocs_ntab_sid),
 ad_composite_fil     FILLER CHAR,
 ad_composite         LOBFILE (ad_composite_fil)    RAW TERMINATED BY EOF,
 ad_sourcetext_fil    FILLER CHAR,
 ad_sourcetext        LOBFILE (ad_sourcetext_fil)       TERMINATED BY EOF,
 ad_finaltext_fil     FILLER CHAR,
 ad_finaltext         LOBFILE (ad_finaltext_fil)        TERMINATED BY EOF,
 ad_fltextn_fil       FILLER CHAR,
 ad_fltextn           LOBFILE (ad_fltextn_fil)          TERMINATED BY EOF,
 ad_photo_fil         FILLER CHAR,
 ad_photo             LOBFILE (ad_photo_fil)        RAW TERMINATED BY EOF,
 ad_graphic_fil       FILLER CHAR,
 ad_graphic           BFILE (CONSTANT "MEDIA_DIR", ad_graphic_fil),
 ad_header            COLUMN OBJECT
 (
  header_name         CHAR,
  creation_date       DATE "mm-dd-yyyy",
  header_text         CHAR,
  logo_fil            FILLER CHAR,
  logo                LOBFILE (ad_header.logo_fil)  RAW TERMINATED BY EOF
 )
)

INTO TABLE textdocs_nestedtab
INSERT 
WHEN table_TYP = 'T'
SID (textdoc_sid)
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
(
 table_typ            FILLER POSITION(1) CHAR,
 document_typ         CHAR,
 formatted_doc_fil    FILLER CHAR,
 formatted_doc        LOBFILE (formatted_doc_fil)   RAW TERMINATED BY EOF,
 textdoc_sid          FILLER CHAR
)
