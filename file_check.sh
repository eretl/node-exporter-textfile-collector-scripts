echo '# TYPE file_exists gauge'
if ! [ -z "$(ls -A /var/log/mysql)" ]; then
        if [ -s /var/log/mysql/*error* ]; then
                echo "file_exists{folder=\"/var/log/mysql\"} 1"
        else
                echo "file_exists{folder=\"/var/log/mysql\"} 0"
        fi
fi
