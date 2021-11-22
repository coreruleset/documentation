#!/bin/bash
grep -Ri -f .github/workflows/en_GB_wordlist content/

# grep found nothing (i.e. grep exited citing failure)? Exit successfully
if [ $? -eq 1 ]
then
  exit 0
fi

# grep found a match? Print the offending matches and then exit citing failure
echo -e "\n****************************** Offending Matches *******************************"
grep -Rio -f .github/workflows/en_GB_wordlist content/
exit 1
