#!/bin/bash
# ######################################################################################################################
# ----------------------------------------------------------------------------------------------------------------------
# Date of last commit:      $Date: 2018-07-12 17:49:49 +0530 (Thu, 12 Jul 2018) $
# ----------------------------------------------------------------------------------------------------------------------
#      script created by Sunil Narhe - 2018-06-18 (YYYY-MM-DD)
#
#      PURPOSE:This script provide User access to SVN repository.
#
#      
#      LAST UPDATES (YYYY-MM-DD): Sunil Narhe : 2018-06-18 : Modified for creating a central script for all instances
#
######################################################################################################################


#Print Help menu
HELP()
{
echo -e "\t--single: To grant access to single repository";
echo -e "\t--url <repo_url>: URL of the Repository";
echo -e "\t--repo <repo_name>: Directory of repository on server";
echo -e "\t--file <file_name>: Input file for multiple repositories";
echo -e "\t\tCSV File should contain Repository Name and Users name";
echo -e "\t--user: Username to have repository access (Used only with '--single')";
echo -e "\t--add: To grant permission for speficifed user/users";
echo -e "\t--remove: To remove permission for specified user/users";
echo -e "\t--help: To print this help menu";
echo -e ""
echo -e "\tExample:"
echo -e "\t   1) Access privide to single repository";
echo -e "\t       sh svn_access.sh --single --url https://ddw-svn-preprod.domainname.com/svn/repos/repoforpt01 --user snarhe --remove";
echo -e "\t       sh svn_access.sh --single --repo /var/www/svn/ddw-preprod_internet/repoforpt40 --remove --user snarhe";
echo -e "\t       Note: You can also provide multiple users with comma(,) separated values like sunil,santosh,aniket";
echo -e "\t   2) Access provide to multple repository"
echo -e "\t       sh svn_access.sh --file input_file.csv --url --add";
echo -e "\t       sh svn_access.sh --file input_file.csv --repo --remove";
}

#Read the content provided by user
IndexOf()    {
    local i=1 S=$1; shift
    while [ $S != $1 ]
    do    ((i++)); shift
        [ -z "$1" ] && { i=0; break; }
    done
    echo "`expr $i + 1`"
}

#Find repo directory for --url
RepoDir()
{
    local repoUrl=$1
    if [[ $repUrl == 'coconet-svn-in-01.domainname.com' ]]
    then
        repo_dir="/var/www/svn/cc1_ind_1004"
    elif [[ $repoUrl == 'coconet-svn-osnl-01.pp.fr.domainname.com' ]]
    then
        repo_dir="/var/www/svn/coconet-svn-osnl"
    elif [[ $repoUrl == 'ddw-svn-preprod-ci.domainname.com' ]]
    then
        repo_dir="/var/www/svn/ddw-preprod_ci"
    elif [[ $repoUrl == 'ddw-svn-preprod-intranet.domainname.com' ]]
    then
        repo_dir="/var/www/svn/ddw-preprod_intranet"
    elif [[ $repoUrl == 'ddw-svn-preprod.domainname.com' ]]
    then
        repo_dir="/var/www/svn/ddw-preprod_internet"
    elif [[ $repoUrl == 'scm-coconet-uat.domainname.com' ]]
    then
        repo_dir="/var/www/svn/scm-coconet-uat"
    elif [[ $repoUrl == 'scm-coconet2-int.domainname.com' ]]
    then
        repo_dir="/var/www/svn/scm-coconet2-int"
    else
        echo -e "$repoUrl is not hostted on `hostname`"
        exit 0;
    fi
}

#Adding Users
AddUser()
{
   local addUser=$1
   echo -e "Info: Backup initiated for authz file $repo_dir/$repo_name/conf/authz"
   DT=`date +%Y-%m-%d-%T`
   cp $repo_dir/$repo_name/conf/authz $repo_dir/$repo_name/conf/authz_$DT ; if [[ $? != 0 ]]; then echo -e "Error: Authz file backup failed"; exit 0; fi
   for user_list in `echo $addUser | sed 's/,/\n/g'`
   do
        sed -i "/$repo_name:/a $user_list = rw" $repo_dir/$repo_name/conf/authz
        echo -e "Info: Access granted to $user_list"
   done
}

#Remove user permission
RemoveUser()
{
   local removeUser=$1
   echo -e "Info: Backup initiated for authz file $repo_dir/$repo_name/conf/authz"
   DT=`date +%Y-%m-%d-%T`
   cp $repo_dir/$repo_name/conf/authz $repo_dir/$repo_name/conf/authz_$DT ; if [[ $? != 0 ]]; then echo -e "Error: Authz file backup failed"; exit 0; fi
   for user_list in `echo $removeUser | sed 's/,/\n/g'`
   do
        sed -i "/^$user_list = rw/d" $repo_dir/$repo_name/conf/authz
        echo -e "Info: Access removed to $user_list"
   done
}

#Main body of script
if [[ $# == 0 ]]
then
    echo -e "Error: At least one parameter is manadatory. Use 'sh $0 --help'";
elif [ $1 == '--help' ]
then
    HELP
else
    parameter_list=$@
    if [[ `echo $parameter_list | grep -e '--single' > /dev/null; echo $?` != `echo $parameter_list | grep -e '--file' > /dev/null ; echo $?` ]] && [[ `echo $parameter_list | grep -e '--single' > /dev/null; echo $?` == 0 ]]
    then
        if [[ `echo $parameter_list | grep -e '--url' > /dev/null ; echo $?` != `echo $parameter_list | grep -e '--repo' > /dev/null ; echo $?` ]] && [[ `echo $parameter_list | grep -e '--user' > /dev/null; echo $?` == 0 ]]
        then
            if echo $parameter_list | grep -e '--url' > /dev/null
            then
                if [[ $# == 6 ]]
                then
                    url_index="`IndexOf '--url' ${parameter_list[@]}`"
                    url_value=`echo $parameter_list | cut -d" " -f$url_index`
                    if [[ `curl -Is $url_value | head -n 1 | wc -l` == 1 ]]
                    then
                        repo_name=`echo $url_value | awk -F'/' '{print $NF}'`
                        MainUrl=`echo $url_value | awk -F'/' '{print $3}'`
                        RepoDir $MainUrl
                        #echo -e "Thank you for --url, value is $url_value, $repo_dir and repo is $repo_name"
                        user_index="`IndexOf '--user' ${parameter_list[@]}`"
                        user_values=`echo $parameter_list | cut -d" " -f$user_index`
                        if [[ `echo $parameter_list | grep -e '--add' > /dev/null; echo $?` == 0 ]]
                        then
                            AddUser $user_values
                        elif [[ `echo $parameter_list | grep -e '--remove' > /dev/null; echo $?` == 0 ]]
                        then
                            RemoveUser $user_values
                        else
                            echo -e "Error: '--add' and '--remove' operational parameter not used"
                        fi
                    else
                        echo -e "Error: Incorrect URL passed"
                    fi
                else
                    echo -e "Error: Required parameter not passed, Use 'sh $0 --single --url $url_value --user snarhe --add' OR 'sh $0 --help' for more details";
                fi
            elif echo $parameter_list | grep -e '--repo' > /dev/null
            then
                if [[ $# == 6 ]]
                then
                    repo_index=`IndexOf '--repo' ${parameter_list[@]}`
                    repo_dir=`echo $parameter_list | cut -d" " -f$repo_index`
                    #echo -e "Thank you for --repo, index is $repo_value"
                    if [[ -d "$repo_dir" ]]
                    then
                        user_index="`IndexOf '--user' ${parameter_list[@]}`"
                        user_values=`echo $parameter_list | cut -d" " -f$user_index`
                        if [[ `echo $parameter_list | grep -e '--add' > /dev/null; echo $?` == 0 ]]
                        then
                            AddUser $user_values
                        elif [[ `echo $parameter_list | grep -e '--remove' > /dev/null; echo $?` == 0 ]]
                        then
                            RemoveUser $user_values
                        else
                            echo -e "Error: '--add' and '--remove' operational parameter not used"
                        fi
                    else
                        echo -e "Error: $repo_dir not available on server, please provide absolute directory path"
                    fi
                else
                    echo -e "Error: Required parameter not passed, Use 'sh $0 --single --repo $repo_dir --user snarhe --add' OR 'sh $0 --help' for more details";
                fi
            else
                echo -e "--url or --repo parameters are must"
            fi
        else
            echo -e "Error: '--url or --repo missing' OR '--user missing' OR '--url and --repo used at the same time'"
        fi
##File operation
    elif [[ `echo $parameter_list | grep -e '--file' > /dev/null; echo $?` == 0 ]]
    then
        if [[ $# == 4 ]]
        then
            if [[ `echo $parameter_list | grep -e '--url' > /dev/null ; echo $?` != `echo $parameter_list | grep -e '--repo' > /dev/null ; echo $?` ]]
            then
                file_index=`IndexOf '--file' ${parameter_list[@]}`
                file_name=`echo $parameter_list | cut -d" " -f$file_index`
                if [ -s $file_name ]
                then
                    if echo $parameter_list | grep -e '--repo' > /dev/null
                    then
                        while read f1 f2
                        do
                            repo_dir=$f1
                            user_values=$f2
                            if [[ -d "$repo_dir" ]]
                            then
                                if [[ `echo $parameter_list | grep -e '--add' > /dev/null; echo $?` == 0 ]]
                                then
                                    AddUser $user_values
                                elif [[ `echo $parameter_list | grep -e '--remove' > /dev/null; echo $?` == 0 ]]
                                then
                                    RemoveUser $user_values
                                else
                                    echo -e "Error: '--add' and '--remove' operational parameter not used"
                                fi
                            else
                                echo -e "Error: $repo_dir not available on server, please provide absolute directory path"
                            fi
                        done < $file_name
                    elif echo $parameter_list | grep -e '--url' > /dev/null
                    then
                        while read f1 f2
                        do
                            url_value=$f1
                            user_values=$f2
                            repo_name=`echo $url_value | awk -F'/' '{print $NF}'`
                            MainUrl=`echo $url_value | awk -F'/' '{print $3}'`
                            RepoDir $MainUrl
                            if [[ `curl -Is $url_value | head -n 1 | wc -l` == 1 ]]
                            then
                                if [[ `echo $parameter_list | grep -e '--add' > /dev/null; echo $?` == 0 ]]
                                then
                                    AddUser $user_values
                                elif [[ `echo $parameter_list | grep -e '--remove' > /dev/null; echo $?` == 0 ]]
                                then
                                    RemoveUser $user_values
                                else
                                    echo -e "Error: '--add' and '--remove' operational parameter not used"
                                fi
                            else
                                echo -e "Error: Incorrect URL passed $url_value"
                            fi
                        done < $file_name
                    fi
                else
                    echo -e "Error: File does not exist or empty" ; exit 0
                fi
            else
                echo -e "Error: '--url or --repo missing' OR '--add or --remove missing' OR '--url and --repo used at the same time'"
            fi
        else
            echo -e "Error: '--single missing' OR '--file missing' OR '--single and --file used at the same time' use 'sh $0 --help' for manual"
        fi
    else
        echo -e "Error: '--single missing' OR '--file missing' OR '--single and --file used at the same time' use 'sh $0 --help' for manual"
    fi
fi


