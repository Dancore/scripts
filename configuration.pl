# This file is only intended for (global) settings, like DB configs etc.

# A filename and path for logging performance measurements:
our $perflogfilename = './performance.log';

# from where we read the csv files:
our $dirpath = "./logfiles";

our $database_name = "test";
our $database_user = "testuser";
our $database_password = "";
# NOTE that "localhost" in psql is (normally) a unix socket addressed by setting host=/tmp:
our $database_host = "/tmp";
# our $database_port = "5432";
our $database_table = "sometable";

our $systemtimezone = 'CEST';

1; # true, true...
