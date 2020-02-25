#' readPhyloTree
#' @param tree a phylo tree object
#' @return a sample IDs of trunk/branches of the phylogenetic tree
#'
#' @examples
#  branches <- readPhyloTree(tree)

readPhyloTree <- function(tree){
  Root <- which(tree$tip.label == "NORMAL")
  tree <- root(tree, Root)
  result <- list()
  for(i in 1:(length(tree$edge.length)+1)){
      result[[i]] <- NA
  }
  end <- tree$edge[which(tree$edge[,2] == Root),1]
  for(i in 1:length(tree$tip.label)){
      row <- tree$edge[which(tree$edge[,2] == i), ]
      if(i == Root){
          next
      }
      result[[i]][2] <- i
      while (TRUE) {
          node <- row[1]
          if(node == end){
              result[[node]] <- append(result[[node]], i)
              break
          }
          else{
              result[[node]] <- append(result[[node]], i)
              row <- tree$edge[which(tree$edge[,2] == node),]
          }
      }
  }
  g <- lapply(result, function(x){
    return(paste(sort(tree$tip.label[x[-1]], decreasing = T),collapse = "∩"))
    })
  edges_label <- unlist(g)[-Root]
  nodes.num <- seq_along(tree$tip.label) - 1
  tree_branch <- edges_label[order(unlist(lapply(edges_label, function(x) length(unlist(strsplit(x, split = "∩"))))))]
  edges.num <- length(strsplit(tail(tree_branch, 1), split = "∩")[[1]])
  tree_branch_Alias <- c(paste(rep("B", length(tree_branch)-1), (length(tree_branch)-1):1, sep = ""), "T")
  tree_sampleID <- data.frame(Branch = tree_branch, Alias = tree_branch_Alias)
  
  return(tree_sampleID)
}