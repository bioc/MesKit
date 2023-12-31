#' @title compareCCF
#' @description Compare the CCF between samples/tumor pairs
#' This function requires CCF for clustering
#' @param maf Maf or MafList object generated by \code{\link{readMaf}} function.
#' @param patient.id Select the specific patients. Default NULL, all patients are included.
#' @param min.ccf The minimum value of CCF. Default 0.
#' @param pairByTumor Pair by tumor types in each patients. Default FALSE.
#' @param use.tumorSampleLabel Logical (Default: FALSE). 
#' Rename the 'Tumor_Sample_Barcode' by 'Tumor_Sample_Label'.
#' @param ... Other options passed to \code{\link{subMaf}}
#' 
#' @return a result list of CCF comparing between samples/tumor pairs
#' @examples
#' maf.File <- system.file("extdata/", "CRC_HZ.maf", package = "MesKit")
#' clin.File <- system.file("extdata/", "CRC_HZ.clin.txt", package = "MesKit")
#' ccf.File <- system.file("extdata/", "CRC_HZ.ccf.tsv", package = "MesKit")
#' maf <- readMaf(mafFile=maf.File, clinicalFile = clin.File, ccfFile=ccf.File, refBuild="hg19")
#' compareCCF(maf)
#' @export compareCCF


compareCCF <- function(maf,
                       patient.id = NULL,
                       min.ccf = 0,
                       pairByTumor = FALSE,
                       use.tumorSampleLabel = FALSE,
                       ...){

  
  processComCCF <- function(m, pairByTumor){
    maf_data <- getMafData(m) %>% 
      tidyr::unite(
        "Mut_ID",
        c(
          "Chromosome",
          "Start_Position",
          "Reference_Allele",
          "Tumor_Seq_Allele2"
        ),
        sep = ":",
        remove = FALSE
      ) %>%
      dplyr::filter(!is.na(.data$CCF))
    
    patient <- getMafPatient(m)
    if(nrow(maf_data) == 0){
      message("Warning: there was no mutation in ", patient, " after filtering.")
      return(NA)
    }
    
    
    ## check if ccf data is provided
    if(! "CCF" %in% colnames(maf_data)){
      stop(paste0("ccfDensity function requires CCF data.\n",
                  "No CCF data was found when generate Maf/MafList object."))
    }
    if(pairByTumor){
      types <- unique(maf_data$Tumor_ID)
      if(length(types) < 2){
        message(paste0("Warning: only one tumor was found in ", patient," according to Tumor_ID. 
          If you want to compare CCF between regions, pairByTumor should be set as 'FALSE'"))
        return(NA)
      }
      
      ## get average CCF
      maf_data <- maf_data %>% 
        dplyr::mutate(CCF = .data$Tumor_Average_CCF)
      pairs <- utils::combn(length(types), 2, simplify = FALSE) 
      pair_name_list <- unlist(lapply(pairs, function(x)paste(types[x[1]],"-",types[x[2]], sep = ""))) 
      pairs <- lapply(pairs, function(x)c(types[x[1]],types[x[2]]))
      
    }else{
      samples <- unique(maf_data$Tumor_Sample_Barcode)
      if(length(samples) < 2){
        message(paste0("Warning: only one sample was found in ",patient))
        return(NA)
      }
      pairs <- utils::combn(length(samples), 2, simplify = FALSE)  
      pair_name_list <- unlist(lapply(pairs, function(x)paste(samples[x[1]],"-",samples[x[2]], sep = "")))
      pairs <- lapply(pairs, function(x)c(samples[x[1]],samples[x[2]]))
    }
    
    
    processComCCFPair <- function(pair, maf_data, pairByTumor){
      S1 <- pair[1]
      S2 <- pair[2]
      if(pairByTumor){
        ccf.pair <- maf_data %>% 
          dplyr::filter(.data$Tumor_ID %in% c(S1, S2)) %>%
          tidyr::unite("Mut_ID2",
                       c("Tumor_ID","Chromosome", "Start_Position", "Reference_Allele", "Tumor_Seq_Allele2"), 
                       sep = ":", remove = FALSE) %>% 
          dplyr::distinct(.data$Mut_ID2, .keep_all = TRUE) %>%
          dplyr::select("Tumor_ID", "Hugo_Symbol", "Mut_ID", "CCF") %>%
          tidyr::pivot_wider(names_from = "Tumor_ID", values_from = "CCF") %>%
          # dplyr::select("Tumor_ID", "Hugo_Symbol", "Mut_ID", "CCF") %>%
          # tidyr::pivot_wider(names_from = "Tumor_ID", values_from = c("CCF", "Clonal_Status")) %>%
          tidyr::drop_na()
          
      }else{
        ccf.pair <- maf_data %>% 
          dplyr::filter(.data$Tumor_Sample_Barcode %in% c(S1, S2)) %>%
          dplyr::select("Tumor_Sample_Barcode", "Hugo_Symbol", "Mut_ID", "CCF") %>% 
          tidyr::pivot_wider(names_from = "Tumor_Sample_Barcode", values_from = "CCF") %>% 
          tidyr::drop_na()
      }
      if(nrow(ccf.pair) == 0){
        message(paste0("Warning: no shared mutaions were detected between ",S1, " and ", S2) )
        return(NA)
      }
      return(as.data.frame(ccf.pair) )
    }
    
    ccf.pair.list <- lapply(pairs, processComCCFPair, maf_data, pairByTumor)
    names(ccf.pair.list) <- pair_name_list
    ccf.pair.list <- ccf.pair.list[!is.na(ccf.pair.list)]
    
    return(ccf.pair.list)
    
  }
  
  
  maf_input <- subMaf(maf,
                      patient.id = patient.id,
                      use.tumorSampleLabel = use.tumorSampleLabel,
                      min.ccf = min.ccf,
                      mafObj = TRUE,
                      ...)
  
  result <- lapply(maf_input, processComCCF, pairByTumor)
  result <- result[!is.na(result)]
  
  if(length(result) == 0){
    return(NA)
   }
  
  return(result)      
}