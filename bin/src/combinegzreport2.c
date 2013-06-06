#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

struct dx {
	char description[200] ;
	int jobid ;
	int sameerror, differror ;
} ;

int get_jobid_matching( int jobidtoget, int maxjobid, struct dx *JDescription  ) {
  int i = 0 ;
  for ( i = 0 ; i <= maxjobid ; i++ ) {
    if ( jobidtoget == JDescription[i].jobid ) 
      return i ;
  }
  return -1 ;
}


int main( int argc, char *argv[] ) {
  #define FERR_DIM 20
  FILE *fin, *fout, *ferr[FERR_DIM];
  char cur_line[2340];
  int linenum = 0;
  int i, f, fn, jobid;
  int foundmatch = 0, nomatch = 0;

  char firstword[2000], secondword[2000];
  char newdescription[2000];
  struct dx *JDescription = NULL;
  int attransition = 0;
  int JobsDescribed = 0;
  char jobidstring[200];
  int jobidtoget;
  int MaxJobId = -1 ;
  int matchingjobid = -1 ;
  int inputsameerrors = 0, inputdifferrors = 0 ;
  int countdifferror = 0, countsameerror = 0 ;
  char *cptr, *replaceloc, *firstoccur, *secondoccur ;
 
  if ( argc < 4 ) {
   printf( "Usage: ./combinegzreport gazebo.results.date.txt OutputGazeboPatchedResults.txt CommonErrReport.txt ... \n" ) ;
   exit(8);
  }

  if ( ( fin = fopen( argv[1], "r" )) == NULL ) {
   printf( "Couldn't open %s for reading!\n", argv[1] ) ;
   exit(8);
  }

  if ( ( fout = fopen( argv[2], "w" )) == NULL ) {
   printf( "Couldn't open %s for writing!\n", argv[3] ) ;
   exit(8);
  }

  for (fn = 0; (argc > fn+3) && (fn < FERR_DIM); fn++) {
    if ( ( ferr[fn] = fopen( argv[fn+3], "r" )) == NULL ) {
      printf( "Couldn't open %s for reading!\n", argv[fn+3] ) ;
      exit(8);
    }
  }

  if (argc > fn+3) {
    printf("Error: too many CommonErrReport.txt files specified; limit is %d\n", FERR_DIM);
    exit(8);
  }
 
  for (f = 0; f < fn; f++) { 
    while (fgets(cur_line, 2280, ferr[f])) {
      if (cur_line[0] != '#') linenum++; // Count non-comment lines
    }
    rewind( ferr[f] ) ;
  }
   
  MaxJobId = linenum ;
  JobsDescribed = ++linenum ;

  JDescription = (struct dx *) calloc( JobsDescribed, sizeof( struct dx ) ) ;
  if ( JDescription == NULL ) {
    printf("Error: Could not allocate enough memory for %d tests, need %d bytes.\n", JobsDescribed, (int) (JobsDescribed * (int) sizeof( struct dx )) ) ;
    exit(8);
  }

  linenum = 0;
  for (f = 0; f < fn; f++) { 
    while(fgets( cur_line, 2280, ferr[f] )) {
      if (cur_line[0] == '#') continue; // skip comment line
      sscanf( cur_line, "%d %[^\n]s", &jobid, newdescription ) ;
      strcpy( JDescription[linenum].description, newdescription ) ;	
      JDescription[linenum].jobid = jobid ;	
      JDescription[linenum].sameerror = 0 ;	
      JDescription[linenum].differror = 0 ;	
  //    printf ("%d %d %s\n", linenum, JDescription[linenum].jobid, JDescription[linenum].description);
      linenum++;  
    }
    fclose( ferr[f] ) ;
  }
  printf("    Read in %d Common Errors\n", linenum ) ;

  for ( linenum = 0 ; linenum <= MaxJobId ; linenum++ ) {
    for ( i = (linenum + 1) ; i <= MaxJobId ; i++ ) {
      if ( JDescription[linenum].jobid == JDescription[i].jobid ) {
        if ( strncmp( JDescription[linenum].description, JDescription[i].description, 10 ) == 0   ) {
          JDescription[linenum].sameerror++ ; inputsameerrors++ ;
        } else {
          JDescription[linenum].differror++ ; inputdifferrors++ ; 
        }
      } 		
    }
  }


 printf("    Found %d same error duplicates and %d different error duplicates in same jobids for Entire History of Errors\n", inputsameerrors, inputdifferrors ) ;

 attransition = 0 ;
 for ( linenum = 0 ; fgets( cur_line, 2280, fin ) != NULL ; linenum++ ) {
	sscanf( cur_line, "%s %s", &firstword, &secondword ) ;
	if ( ( strcmp( firstword, "Total" ) == 0 ) && ( strcmp( secondword, "node" ) == 0 ) ) {
		attransition = 1 ;
	}
	if ( attransition > 1 ) {
		if ( strlen( cur_line ) < 3  ) { 
			attransition = 2 ;
		} else if ( strstr( cur_line, "gazebo" ) != NULL ) {
			attransition = 3 ;
		} else {
		attransition = 4 ;
		}
	}
	switch ( attransition ) {
		case 0 :
			fputs( cur_line, fout ) ; break ;
		case 1 :
			fputs( cur_line, fout ) ; attransition = 2 ; break ;
		case 2 :
			fputs( cur_line, fout ) ; break ;
		case 3 :
			// get jobid from cur_line 
			fputs( cur_line, fout ) ;
			jobidtoget = -1 ;
		        firstoccur = strstr( cur_line, "__" ) ;
			if ( firstoccur != NULL ) {
				secondoccur = strstr( (firstoccur + 2), "__" ) ;
				if ( secondoccur != NULL  ) {
					for ( i = 0 ; i < strlen( secondoccur ) ; i++ ) {
						// if ( isnumber( (int) secondoccur[i+2] )  ) {
						if ( isdigit( (int) secondoccur[i+2] )  ) {
							jobidstring[i] = secondoccur[i+2] ;
						} else {
							jobidstring[i] = '\0' ;
							jobidtoget = atoi( jobidstring ) ;
							// printf (" new jobidtoget: %d\n", jobidtoget);
							break ;
						}

					}
					
				} else {
					printf("WARNING: second occurance of __ not found in string %s\n", cur_line ) ;
				}

			} else {
				printf("WARNING: first occurance of __ not found in string %s\n", cur_line ) ;

			}	

			break ;
		case 4 : 
			// printf (" looking for jobid (%d) to match\n", jobidtoget );
			// if jobid matches a current job description replace description with new description 
			if (( matchingjobid = get_jobid_matching( jobidtoget, MaxJobId, JDescription ) ) > -1 ) {
			//	printf (" reason: %s, jobid: %d, index: %d\n", JDescription[matchingjobid].description, jobidtoget, matchingjobid );
				replaceloc = strstr( cur_line, "description" ) ;
				for ( cptr = cur_line ; cptr < replaceloc ; cptr++ ) {
					fputc( *cptr, fout ) ;
				}
				fputs( JDescription[matchingjobid].description, fout ) ;
				if ( JDescription[matchingjobid].sameerror > 0 ) {
					fprintf(fout, " " ) ;
					countsameerror += JDescription[matchingjobid].sameerror ;
					for ( i = 0 ; i < JDescription[matchingjobid].sameerror ; i++ ) 
						fprintf(fout, "*" ) ;
				} 
				if ( JDescription[matchingjobid].differror > 0 ) {
					fprintf(fout, " " ) ;
					countdifferror += JDescription[matchingjobid].differror ;
					for ( i = 0 ; i < JDescription[matchingjobid].differror ; i++ ) 
						fprintf(fout, "@" ) ;
				} 
				fprintf(fout, "\n" ) ;
				foundmatch++ ;

			} else {
				fputs( cur_line, fout ) ;
				nomatch++ ;
			}	
			
			break ;
		default : 
			printf("WARNING: Shouldn't be here, attransition = %d currrent line [%d] is %s\n", attransition, linenum, cur_line ) ;

			break ;
	}

 }

 printf( "    Multiple Error for same jobid accounting included in report - Same Error Duplicates: %d Different Error Duplicates: %d\n", countsameerror, countdifferror  ) ;
 printf( "SUMMARY: lines matched %d unmatched %d match percentage: %.2f\n", foundmatch, nomatch, (float) foundmatch / (float) (foundmatch + nomatch) * 100.0  ) ;
   
 fclose( fin ) ;
 fclose( fout ) ;

 return 1 ;
}

