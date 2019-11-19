gc()	# unnecessary but sometimes helps clean up ghost threads from failed runs	
set.seed(Sys.time())	# not reproducible, but also prevents idiosyncratic results

library("dplyr")
library("readr")
library("foreach")
library("doParallel")		# there are other back-ends you can use

# outfile = "" is what gets the foreach loop to print to the screen
cluster <- makeCluster(3, outfile = "")		# think carefully about how many cores you want to use, which should be kind to other people using the computer and at least one less than the number of cores available, and note that hyperthreading gives sublinear performance improvements 
registerDoParallel(cluster)

# create a list of Markov processes, which are row-normalized matrices where the ij element is the probability of transitioning from state i to state j in one time step
mat_list <- list()

# variables for the Markov processes -- ONCE YOU HAVE THE CODE RUNNING AND UNDERSTAND IT, TRY MAKING THESE NUMBERS BIGGER TO TAKE ADVANTAGE OF THE PARALLELIZATION
mat_total <- 10			# number of Markov processes
dimension <- 10		# size of each Markov process = dimension of each matrix

# generate random Markov processes
for (mat in 1:mat_total) {
	mat_temp <- matrix(sample(c(0, 0.1, 0.1, 2), dimension^2, replace = TRUE), nrow = dimension, ncol = dimension)
	mat_list[[mat]] = sweep(mat_temp, MARGIN = 1, FUN = "/", STATS = rowSums(mat_temp))		# row-normalize to unity turning a random matrix into a Markov process
}

# save the loop to a variable so what it returns isn't just printed to the screen
# without .combine = rbind the loop would return a list
# use .packages to pass into each core the libraries the loop needs 
stability <- foreach (mat = 1:mat_total, .combine = rbind, .packages = c("tibble", "dplyr", "expm")) %dopar% {
	# remember, this only works because the cluster was made with the parameter outfile = ""	
	print(mat)

	# row-normalized matrices are Markov processes which converge on their stationary distribution (if it exists) when raised to successive powers, usually in less than 100 steps
	stationary_dist <-(mat_list[[mat]] %^% 1e2)[1,]

	# writing to disk is the safest way to run things in parallel
	write.table(stationary_dist, file = paste0("stationary_distribution_", mat, ".csv"), sep = ",", row.names = FALSE, col.names = FALSE)

	# last line gets returned
	return(stationary_dist)
}

# don't forget to free up the cores you registered
stopCluster(cluster)

# view the stationary distributions of each simulated Markov process
stability

# assemble them from the files you wrote to disk
output_files <- list.files(pattern = "stationary_distribution")
output_files = output_files[substr(output_files, 25, nchar(output_files)-4) %>% as.numeric %>% order]	# reorder files numerically

# iterate through each stationary distribution file and add them to the pre-allocated matrix 
stability_assembled <- matrix(NA, nrow = mat_total, ncol = dimension)

for (file in 1:mat_total) {
	stability_assembled[file,] = readr::read_csv(output_files[file], col_names = FALSE)$X1
}

# there may be some numerical differences that result in all(stability_assembled == stability) = FALSE
stability_assembled
