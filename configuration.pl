# This file is only intended for (global) settings, like DB configs etc.

# bundle data into periods (currently per minute) and recalc measurements, if set:
our $do_period_calc = 0;

# from where we read the csv files:
our $dirpath = "./logfiles";

our $database_name = "test";
our $database_user = "testuser";
our $database_password = "";
# NOTE that "localhost" in psql is (normally) a unix socket addressed by setting host=/tmp:
our $database_host = "/tmp";
# our $database_port = "5432";
our $database_table = "sometable";


1; # true, true...