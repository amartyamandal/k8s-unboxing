#!/bin/bash
#./setup.sh all / cp / wrk / del / del wrk /
if [ $# -eq 0 ]
then
    echo "No arguments supplied"
else
    source ./configure/functions/utility.sh
    INPUT=""
    for i
    do
    INPUT+=$i" "
    done
    INPUT=$(echo $INPUT | xargs)
    validateInput INPUT
    printf "#!/bin/bash\n\n" > ./run.sh
    printf "source ./configure/functions/utility.sh\n" > ./run.sh
    sudo chmod +x ./run.sh 

    parse_yaml k8s-config.yaml >> ./run.sh
    printf "validate_yaml_input\n" >> ./run.sh
    if [[ $1 == del ]]
    then
        if [ -z "$2" ]
        then
            printf "./destroy.sh \$k8s_provider\n" >> ./run.sh
        # elif [[ $2 == wrk ]]
        # then
        #     printf "./destroy.sh \$k8s_provider wrk\n" >> ./run.sh
        fi
    elif [[ $1 == all ]]
    then
        printf "./setup_start.sh\n" >> ./run.sh
        printf "./setup_cp.sh\n" >> ./run.sh
        printf "./setup_end.sh\n" >> ./run.sh
        printf "./setup_nd.sh\n" >> ./run.sh
        printf "./scripts/setup-cni-plugin-dns.sh\n" >> ./run.sh
    elif [[ $1 == cp ]]
    then
        printf "./setup_start.sh\n" >> ./run.sh
        printf "./setup_cp.sh\n" >> ./run.sh
        printf "./setup_end.sh\n" >> ./run.sh
    elif [[ $1 == scale ]]
    then
        if [ -z "$2" ]
        then
            printf "./setup_nd.sh\n" >> ./run.sh
        fi
    elif [[ $1 == make ]]
    then
        printf "./make.sh" >> ./run.sh
    elif [[ $1 == build ]]
    then
        printf "scripts/build-k8s.sh" >> ./run.sh
    fi
    ./run.sh
fi