#!/bin/bash

acceptance_testing=""

function heading(){
message=$1
echo " "
echo "======================================================================"
echo " ${message}"
echo "======================================================================"
echo " "

}

function msg(){
message=$1
echo " "
echo " ${message}"
echo " "
}

function msg(){
message=$1
echo " "
echo "[${message}]"
echo " "
}


function check_syntax_quality(){
heading "[Starting] Syntax and code quality check using foodcritic tool"

	check_syntax_quality=`echo foodcritic $WORKSPACE/cookbook`
	$check_syntax_quality>$WORKSPACE/log/check_syntax_quality.txt
	cat $WORKSPACE/log/check_syntax_quality.txt	
}


function acceptance_testing(){
heading "[Starting] Acceptance Testing using Test Kitchenc"
        pushd $WORKSPACE/cookbook
        for entry in "$WORKSPACE/cookbook/nodesets"/*
		do
		sudo cat $WORKSPACE/cookbook/nodesets/$entry > $WORKSPACE/cookbook/.kitchen.yml
		 node_file=$(basename $entry)
		  filename="${node_file%.*}"
		  msg "OS: $filename"
                  result=`echo sudo kitchen test -l=debug`
                  $result>$WORKSPACE/log/acceptance/acceptance_testing.txt
                  sudo sed -i 's/\(\[32m\|\[0m\)//g' $WORKSPACE/log/acceptance/${filename}.txt
                  cat $WORKSPACE/log/acceptance/${filename}.txt
                 done
        popd
}


function unit_testing_resource_coverage(){

heading "[Starting] Unit Testing and Code Coverage Using rspec-puppet tool"
        pushd $WORKSPACE/cookbook
                unit_testing_resource_coverage=`echo rspec $WORKSPACE/cookbook/spec/*_spec.rb`
                $unit_testing_resource_coverage>$WORKSPACE/log/unit_testing_resource_coverage.txt
                cat $WORKSPACE/log/unit_testing_resource_coverage.txt

                #This for just report purpose
        #       resouce_coverage=`echo rspec $WORKSPACE/project/spec/unit/*_spec.rb`
                #$resouce_coverage>$WORKSPACE/log/resouce_coverage.txt
        popd
}


function result(){
heading "Result"


msg "1. Check metadata quality : "

	
	if [ ! -s $WORKSPACE/log/check_syntax_quality.txt ]; then
		echo "No errors"
		CHEF_SYNTAX_QUALITY="<span class='success'>No errors</span>"
	else
		cat $WORKSPACE/log/check_syntax_quality.txt
		value=$(<$WORKSPACE/log/check_syntax_quality.txt)
		CHEF_SYNTAX_QUALITY="<span class='error'>${value}</span>"
	fi
	

msg "2. Unit Testing"

        unit_testing=`grep --text -P '^[0-9]+ examples, [0-9]+ failures' $WORKSPACE/log/unit_testing_resource_coverage.txt`
        echo $unit_testing
        PUPPET_UNIT_TEST_TIME_TAKEN=`grep -oP '\Finished in\K[^\(f]+' $WORKSPACE/log/unit_testing_resource_coverage.txt`

        if [[ "$unit_testing" =~ "^[0-9]+ examples, 0 failures" ]]; then
                PUPPET_UNIT_TEST_RESULT_MAIL="<span class='error'>${unit_testing}</span>"
        else
                PUPPET_UNIT_TEST_RESULT_MAIL="<span class='success'>${unit_testing}</span>"
        fi

msg "3. Resource Coverage"

        value=$(grep -oP '\(\K[^\)]+' $WORKSPACE/log/unit_testing_resource_coverage.txt | tail -1)
        PUPPET_RESOURCE_COVERAGE_MAIL=${value}
        echo $value

msg "4. Acceptance testing : "
        PUPPET_ACCEPTANCE_TESTING_MAIL=""
        for entry in "$WORKSPACE/project/spec/acceptance/nodesets"/*
	do
	  node_file=$(basename $entry)
	  filename="${node_file%.*}"
          final_result=`grep --text -P '[0-9]+ examples, [0-9]+ failures' $WORKSPACE/log/acceptance/${filename}.txt`
          echo "${filename}---------------${final_result}"
          time_taken=`grep -oP '\Finished in\K[^\(f]+' $WORKSPACE/log/acceptance/${filename}.txt`
          if [[ "$final_result" =~ "^[0-9]+ examples, 0 failures" ]]; then
                PUPPET_ACCEPTANCE_TESTING_MAIL="${PUPPET_ACCEPTANCE_TESTING_MAIL}<tr><td>acceptance_testing.txt</td><td><span class='error'>${final_result}</span></td><td>${time_taken}</td></tr>"
          else
                PUPPET_ACCEPTANCE_TESTING_MAIL="${PUPPET_ACCEPTANCE_TESTING_MAIL}<tr><td>acceptance_testing.txt</td><td><span class='success'>${final_result}</span></td><td>${time_taken}</td></tr>"
          fi
        done

}

function init(){

mkdir $WORKSPACE/log
mkdir $WORKSPACE/log/acceptance
mkdir $WORKSPACE/report

MAIL_JOB_URL="http://104.196.46.29:8080/job/chef-google_cloud_dns/HTML_Report/"
MAIL_JOB_NAME=$JOB_NAME

pushd $WORKSPACE/cookbook
        sudo bundle install
popd

}

init
check_syntax_quality
unit_testing_resource_coverage
acceptance_testing
result

pushd $WORKSPACE/scripts
        eval "echo \"$(< chef_report.html)\"" > $WORKSPACE/report/chef_report.html
popd
