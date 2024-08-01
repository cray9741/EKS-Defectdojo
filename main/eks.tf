data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

#setup kms key for eks secrets
resource "aws_kms_key" "eks_kms_key" {
  description             = "KMS key for EKS secrets"
  deletion_window_in_days = var.kms_deletion_window_in_days
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}




###
### kubernetes manifest's
###

resource "kubectl_manifest" "defectdojo-tls" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  annotations:
    cert-manager.io/alt-names: defectdojo.secops-ba.win
    cert-manager.io/certificate-name: defectdojo-tls
    cert-manager.io/common-name: defectdojo.secops-ba.win
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-group: cert-manager.io
    cert-manager.io/issuer-kind: ClusterIssuer
    cert-manager.io/issuer-name: letsencrypt-staging
    cert-manager.io/uri-sans: ""
  creationTimestamp: "2024-07-01T18:30:27Z"
  labels:
    controller.cert-manager.io/fao: "true"
  name: defectdojo-tls
  namespace: defectdojo
  resourceVersion: "5566"
  uid: 537554f4-9375-4f17-ab8d-98889dbc00b7
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZBVENDQSttZ0F3SUJBZ0lTQXcwOHZjS0lvT1FEWmxkc1hYdWswaEhMTUEwR0NTcUdTSWIzRFFFQkN3VUEKTURNeEN6QUpCZ05WQkFZVEFsVlRNUll3RkFZRFZRUUtFdzFNWlhRbmN5QkZibU55ZVhCME1Rd3dDZ1lEVlFRRApFd05TTVRFd0hoY05NalF3TnpBeE1UY3pNREkyV2hjTk1qUXdPVEk1TVRjek1ESTFXakFqTVNFd0h3WURWUVFECkV4aGtaV1psWTNSa2IycHZMbk5sWTI5d2N5MWlZUzUzYVc0d2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUIKRHdBd2dnRUtBb0lCQVFEQW1kMnpnS1NUVHhpbUFWZWJValdyR3hLOGU3aGx3bjBQdjA5bTlQRmRBLzVFamdBawpwRHBnMTBKU21HNXNMSEIwRUxzOSt1OGVKVXU0VDM1ZktydDVudDQ0S3VQdU8ySGRUUk1CdzVIV21DV0cxbE9nCmRPOXdlek40aE5qa2pkYWg2MVF3eGUrb01ZU2pWdmUycFpEL0pPYXd0MkRoRXpQM3ZGOXlNT1R5OFNwM3JDN1IKUUNyVWQvSUpMeHRGWWR6aTQrenB6MkVKMXZWdGpKTlJmek5MTnJIbzFGZktWL3RudENiNmZqalVmcUZHT0JqOQozdGZqZDA5bVRNOHp6ZVdrN2l0OTFtMThxUjRFUG51OFQzRlc2TTlIdnBUczJIWnpBclo3aWlidnUrZ2pTd2NICjlmMG5pSng4UEdLT3V1MXdzdS92bmwzQ3FRcncrTHMzTlE2cEFnTUJBQUdqZ2dJZE1JSUNHVEFPQmdOVkhROEIKQWY4RUJBTUNCYUF3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdFR0NDc0dBUVVGQndNQ01Bd0dBMVVkRXdFQgovd1FDTUFBd0hRWURWUjBPQkJZRUZKNWdzY2Y4ZFpXQjdDNTN3TjZRQUJnTU9jSW5NQjhHQTFVZEl3UVlNQmFBCkZNWFBScVRxOU1QQWVteVZ4QzJ3WHBJdkp1TzVNRmNHQ0NzR0FRVUZCd0VCQkVzd1NUQWlCZ2dyQmdFRkJRY3cKQVlZV2FIUjBjRG92TDNJeE1TNXZMbXhsYm1OeUxtOXlaekFqQmdnckJnRUZCUWN3QW9ZWGFIUjBjRG92TDNJeApNUzVwTG14bGJtTnlMbTl5Wnk4d0l3WURWUjBSQkJ3d0dvSVlaR1ZtWldOMFpHOXFieTV6WldOdmNITXRZbUV1CmQybHVNQk1HQTFVZElBUU1NQW93Q0FZR1o0RU1BUUlCTUlJQkJRWUtLd1lCQkFIV2VRSUVBZ1NCOWdTQjh3RHgKQUhjQVB4ZExUOWNpUjFpVUhXVWNoTDRORXUyUU4zOGZoV3Jyd2I4b2hlejRaRzRBQUFHUWI1QUFSQUFBQkFNQQpTREJHQWlFQTJTNUQrWVdEYU4zejRPeXFSUXNtemVTUFdOWjNxR1YxNEtnc3MvMGMyQTRDSVFDWVUvRnNPQVJECmE3WVJsTi8yN1h0SHQ1MEllaVJwVTlQcEJhU1dtczVDYlFCMkFCbVlFSEVKOE5aU0xqQ0EwcDQvWkx1RGJpak0KK1E5U2p1N2Z6a28vRnJUS0FBQUJrRytRQUhFQUFBUURBRWN3UlFJaEFLL1ZTQ2dtUjE1VUpxUXBSWHZ1UEZhTwpHUEh4azBhUGFtZzJ2S0YvRmd5REFpQjI2MzVQaCthWmU0RHQ5WkxmUHczWHN2cnNxQUVZWk1OamhsQy9jVnhnCmh6QU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFueTdVbU5odmtudVFlSm8rekJ0M2ozOHMzUTN3Z1grWWxNbloKeHVtWmdmaTFTV3pTeWlSK2N3aXpsR3NLcHpGVE82UVVUU2hJUmVrdndmVlp1MTQrRkxlNmFiTWdmNml4ekgvKwovSkFLMVVpNGY0dGRjSFdWYlZjbVBCS0VSY1lQczdZYjVMalkwTEt4TUV4L054MHdpSGF5RGdQUzUwbFVFc01ICjBrNitFQmJCZlVKZnJKV2ZLdFNpWTNaRUpqNEpEU1dXYUJYVnM2SUtrUVBUMVFRODZaTXpVK1BIdjdhamtxN3gKUlJBS3RjaUZaWDg1SERub0h5NjVveGhUNjRTb3d6b0JDUDVSNFdjMlZ4K3RuaDVRWHMwRGFjeDRvMW11N0FjSQpPRVVVRmtuOGF5YVlTaXNBaG9lVnBsQk1uYjV3WEJyb2Z2ZnFKUDBzUHhzc2JDeGZUUT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KLS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBd0puZHM0Q2trMDhZcGdGWG0xSTFxeHNTdkh1NFpjSjlENzlQWnZUeFhRUCtSSTRBCkpLUTZZTmRDVXBodWJDeHdkQkM3UGZydkhpVkx1RTkrWHlxN2VaN2VPQ3JqN2p0aDNVMFRBY09SMXBnbGh0WlQKb0hUdmNIc3plSVRZNUkzV29ldFVNTVh2cURHRW8xYjN0cVdRL3lUbXNMZGc0Uk16OTd4ZmNqRGs4dkVxZDZ3dQowVUFxMUhmeUNTOGJSV0hjNHVQczZjOWhDZGIxYll5VFVYOHpTemF4Nk5SWHlsZjdaN1FtK240NDFINmhSamdZCi9kN1g0M2RQWmt6UE04M2xwTzRyZmRadGZLa2VCRDU3dkU5eFZ1alBSNzZVN05oMmN3SzJlNG9tNzd2b0kwc0gKQi9YOUo0aWNmRHhpanJydGNMTHY3NTVkd3FrSzhQaTdOelVPcVFJREFRQUJBb0lCQUI1WEhzbXNOa0RPY1ArVgpyb3RWUkFjVVdMdEFjaWYxbjJYZnFVNTZ2NXI3aWc2YW9BTWxxOXlkakdFZWlpYVlTWTYvSS8vN2k3ZWdBSEdrCmRDL2h0MjdOVEF4bEZVcnVKOWlJejdtemFVSDQ3ZEJ6NnZDWCt6QW8rRTYvL3JyaWJURk10UktKMjlzUEVlbjUKUlVTTWlHN3BEVDVCWlEyUHpOdjEzTU5NV0lTOG13TGFvVkoxVjNSdEpyTm5GaUU4QmpYNDlTUmJpQWdlQUhQUgo2cmd5NFZ5Sk5xZURhK3M2K0dJL3VFa2dGTjlnc3R2ekFvUVQ2UjdoNTVhUUI5Vklmd2hleUhLS2g5UHp2dFl0CjZ1NS80RXpJOXZMNWhvY3hLM0t0WkhmbHoxU3M4c2l2UGp4SnlWeENEZG02ejlQU20vcWQ5TGU1R2xuTU1lN3YKeFZFSStBRUNnWUVBMVA4ODcwNk1RZm5qdy9SbytNYkRnTjdOaW91QTNYWW8zM3lWbzB4azQrQkFJSU9nZ1krcgpRUFJCaGNQTUtJdlpNQzJFdEtiNWVrek1IOEhyNHBiUDdwRXNQRkVOaXc0elBCaWUxVzUweUlUdWYwY05PTC9PClFUTVQxYldDVW1ZSy8zUWptL2hJbmMxQ0xCWFVHaXpZTXRncFk4YkI4TmlnSTZPN0poNHJaOEVDZ1lFQTUzeDEKNDZNU0Z0VWJ5aFpxY3RQZGpnNDVuZ3ZFVm5TdTl0bkxvUjFEdXo5MHAyV01PZGlCL1JMdjF0bytxUXRQWkVrTwpyblJMVEtoWkdRUWFWK1o3SVdpRVVidTgwdjc4VDEvWjhaT0ROUFJEMFBKTWpLa0h3eGNNS01BNHBpZjhUZEJVCnhlMTFGOG5mMC8wT0ZXODNKRExzSjczTE52dnNwRjlaY28rYm9Pa0NnWUVBcHdKWENpRWgwdDJZbk41NHJKQlYKWFNmV0xJc0VDU0lNSEdoNGdHbDNOa0p3cGMzdnZZY2tOYk1QNlUzRU9BcW55cUgyU3h3ZHc2cVI1MWpMbDRpLwpFNFdiRk5STTlUcTJLNm4yYU0zS0hpdzFRWEU1eWNTRGVoWU51R1V4QVdEbndMT1U5RWZ5MEdEUVFQY0FyMkY0ClNDMjhEbk1iUUxqcW4rZFM2Q21CeVVFQ2dZQUttbjdqOElKUm5XMXFjbUJwNWg2TjlVVGFZbnVaNGpwcGdFeDkKa3RPWmJpeXZ4azBJRVV6VEJOMExvRytpV3F4R1VicGtiMXRMcGFKL0xOcndEOVN3RVJPT2t1VHhYVkM5YWd5WApya1FpVnRZTWFpenJmSXFvZXhQSmdoU1dOOXFzemRBMFNNNUdTcThBRE9WcVFlL3FycEoydDVEcGNkekRJc0w4CkptdmdrUUtCZ0UvZS9waG4yaVpjaFJmdHFDRmluazk1cmdHRFRITHVtL2dQMnU1dlBQTVI4UitaZnZhYnBVUG8KWVV5TnQwSUYyYXJObHRmY1BFckVMYVBKb0FUWSszYUtxNlBvSTYrWEdqb09NUHlZUmVUSU1mZ2pVSlY1SUpZcApwMHkrb2hjMk00bU8wZUM0bEpwY2RIVnRkYnRzNDNUYTU0bGxtU2xVajJwNE94eUZiOXZCCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBd0puZHM0Q2trMDhZcGdGWG0xSTFxeHNTdkh1NFpjSjlENzlQWnZUeFhRUCtSSTRBCkpLUTZZTmRDVXBodWJDeHdkQkM3UGZydkhpVkx1RTkrWHlxN2VaN2VPQ3JqN2p0aDNVMFRBY09SMXBnbGh0WlQKb0hUdmNIc3plSVRZNUkzV29ldFVNTVh2cURHRW8xYjN0cVdRL3lUbXNMZGc0Uk16OTd4ZmNqRGs4dkVxZDZ3dQowVUFxMUhmeUNTOGJSV0hjNHVQczZjOWhDZGIxYll5VFVYOHpTemF4Nk5SWHlsZjdaN1FtK240NDFINmhSamdZCi9kN1g0M2RQWmt6UE04M2xwTzRyZmRadGZLa2VCRDU3dkU5eFZ1alBSNzZVN05oMmN3SzJlNG9tNzd2b0kwc0gKQi9YOUo0aWNmRHhpanJydGNMTHY3NTVkd3FrSzhQaTdOelVPcVFJREFRQUJBb0lCQUI1WEhzbXNOa0RPY1ArVgpyb3RWUkFjVVdMdEFjaWYxbjJYZnFVNTZ2NXI3aWc2YW9BTWxxOXlkakdFZWlpYVlTWTYvSS8vN2k3ZWdBSEdrCmRDL2h0MjdOVEF4bEZVcnVKOWlJejdtemFVSDQ3ZEJ6NnZDWCt6QW8rRTYvL3JyaWJURk10UktKMjlzUEVlbjUKUlVTTWlHN3BEVDVCWlEyUHpOdjEzTU5NV0lTOG13TGFvVkoxVjNSdEpyTm5GaUU4QmpYNDlTUmJpQWdlQUhQUgo2cmd5NFZ5Sk5xZURhK3M2K0dJL3VFa2dGTjlnc3R2ekFvUVQ2UjdoNTVhUUI5Vklmd2hleUhLS2g5UHp2dFl0CjZ1NS80RXpJOXZMNWhvY3hLM0t0WkhmbHoxU3M4c2l2UGp4SnlWeENEZG02ejlQU20vcWQ5TGU1R2xuTU1lN3YKeFZFSStBRUNnWUVBMVA4ODcwNk1RZm5qdy9SbytNYkRnTjdOaW91QTNYWW8zM3lWbzB4azQrQkFJSU9nZ1krcgpRUFJCaGNQTUtJdlpNQzJFdEtiNWVrek1IOEhyNHBiUDdwRXNQRkVOaXc0elBCaWUxVzUweUlUdWYwY05PTC9PClFUTVQxYldDVW1ZSy8zUWptL2hJbmMxQ0xCWFVHaXpZTXRncFk4YkI4TmlnSTZPN0poNHJaOEVDZ1lFQTUzeDEKNDZNU0Z0VWJ5aFpxY3RQZGpnNDVuZ3ZFVm5TdTl0bkxvUjFEdXo5MHAyV01PZGlCL1JMdjF0bytxUXRQWkVrTwpyblJMVEtoWkdRUWFWK1o3SVdpRVVidTgwdjc4VDEvWjhaT0ROUFJEMFBKTWpLa0h3eGNNS01BNHBpZjhUZEJVCnhlMTFGOG5mMC8wT0ZXODNKRExzSjczTE52dnNwRjlaY28rYm9Pa0NnWUVBcHdKWENpRWgwdDJZbk41NHJKQlYKWFNmV0xJc0VDU0lNSEdoNGdHbDNOa0p3cGMzdnZZY2tOYk1QNlUzRU9BcW55cUgyU3h3ZHc2cVI1MWpMbDRpLwpFNFdiRk5STTlUcTJLNm4yYU0zS0hpdzFRWEU1eWNTRGVoWU51R1V4QVdEbndMT1U5RWZ5MEdEUVFQY0FyMkY0ClNDMjhEbk1iUUxqcW4rZFM2Q21CeVVFQ2dZQUttbjdqOElKUm5XMXFjbUJwNWg2TjlVVGFZbnVaNGpwcGdFeDkKa3RPWmJpeXZ4azBJRVV6VEJOMExvRytpV3F4R1VicGtiMXRMcGFKL0xOcndEOVN3RVJPT2t1VHhYVkM5YWd5WApya1FpVnRZTWFpenJmSXFvZXhQSmdoU1dOOXFzemRBMFNNNUdTcThBRE9WcVFlL3FycEoydDVEcGNkekRJc0w4CkptdmdrUUtCZ0UvZS9waG4yaVpjaFJmdHFDRmluazk1cmdHRFRITHVtL2dQMnU1dlBQTVI4UitaZnZhYnBVUG8KWVV5TnQwSUYyYXJObHRmY1BFckVMYVBKb0FUWSszYUtxNlBvSTYrWEdqb09NUHlZUmVUSU1mZ2pVSlY1SUpZcApwMHkrb2hjMk00bU8wZUM0bEpwY2RIVnRkYnRzNDNUYTU0bGxtU2xVajJwNE94eUZiOXZCCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
kind: Secret
metadata:
  annotations:
    cert-manager.io/alt-names: defectdojo.secops-ba.win
    cert-manager.io/certificate-name: defectdojo-tls
    cert-manager.io/common-name: defectdojo.secops-ba.win
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-group: cert-manager.io
    cert-manager.io/issuer-kind: ClusterIssuer
    cert-manager.io/issuer-name: letsencrypt-staging
    cert-manager.io/uri-sans: ""
  creationTimestamp: "2024-07-01T18:30:27Z"
  labels:
    controller.cert-manager.io/fao: "true"
  name: defectdojo-tls
  namespace: defectdojo
  resourceVersion: "5566"
  uid: 537554f4-9375-4f17-ab8d-98889dbc00b7
type: kubernetes.io/tls
YAML


}

resource "kubectl_manifest" "cert-manager-webhook-ca" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: cert-manager-webhook-ca
  namespace: cert-manager
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"ca.crt":"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURKVENDQWcyZ0F3SUJBZ0lVUGYvTW14MFRGU21KenZwc3BsZ3dhMk5ERVkwd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0lqRWdNQjRHQTFVRUF3d1hZMlZ5ZEMxdFlXNWhaMlZ5TFhkbFltaHZiMnN0WTJFd0hoY05NalF3TnpJdwpNRFl6TnpVNVdoY05NalV3TnpJd01EWXpOelU1V2pBaU1TQXdIZ1lEVlFRRERCZGpaWEowTFcxaGJtRm5aWEl0CmQyVmlhRzl2YXkxallUQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUltaThhNmsKLzByM2dTSnNCRnZHRnVGNC9JZGZuVk9yRDJFaVZjcTN3a2JHTkJwWTN4UjVCTERnNE13YjVaZUl1YUdBeTkxZAphYjNMdVhJTVhDdWlMUGdsVHJVUnkxcGdtUm9HbDN6MEd2RnA0ekRCNzN0R3g0SHpKU2FleHEycm8zV3dOdHlwCkQ4Znhzejd0ZEYzQVlmM2sxYitsNjF4M3FHT3hiL0tmMi9tdE4wTW9SOWVMc0JaeGU2YWpzVG1zbFFmZ1hnaFMKNXI1US9BSGUzb1Z0TngyTTZqc1ZudW1JNEhTd2dkTFI2akoxTjJNTXh4VXhHdy9uNlJFU3U0QUwwbi96a2dySQpMNVUweXZtdm9iVmMydklSL1B6VTk2c1UxM0ZKazhqNmV5OGZkM0Y1TmRwN3E0bkdLVDByTkVtSlZQWjRHOE1JCk1GZXVvdWdnUU56cXg5MENBd0VBQWFOVE1GRXdIUVlEVlIwT0JCWUVGTFpVZ1FIbmdGeGhDZWY5YjhzUHp3cVQKamlycU1COEdBMVVkSXdRWU1CYUFGTFpVZ1FIbmdGeGhDZWY5YjhzUHp3cVRqaXJxTUE4R0ExVWRFd0VCL3dRRgpNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEZWYwRHg0SU56WWRzVVNKRG9MYW9kUmF6clFVYlNLCjBNak52ZE9lTlhQVG12WEZSc2FYMzRzOXVhNDB0OStGS3VNSlBIQnBwUzBLZmZ2NGVWdHpEWlkzTHhVU21vMmgKZkdPNkJTdE1WbVBycG5jWE9mNzlmTDhlZkkwd1JNdDRnbHQvUjBGamhYRDhlRGJsQzhOU0ZqUmlSdTJXZ1ZGRQpBQ1hrUVUvVkt1TmtXK01pOXU0ei96a1lvYmw2VmF2SmVtS1RiTzZ3TSs2b3BkdG0xMFFyZmNwZDgwbW9mMkJKClRmbU0rdGJ4RmExWkdPSDVUUGVZL1JERWxMUlBOcDh0blZqdW9qVmdTaTcrOTc4aUVxZlpOL3dSVWxSRFhDWlQKZElpUkI2MGMxbzEyTm0rYUNhRUtWYmRVL3dOSzdQbjVSdU9jN3JNK1NHZjNoMGhMcnlKMm1vdz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=","tls.crt":"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJBQ0ZEYThQTXAyOXNuRGRVd2hJYThTZG5sV21xM1JNQTBHQ1NxR1NJYjNEUUVCQ3dVQU1DSXgKSURBZUJnTlZCQU1NRjJObGNuUXRiV0Z1WVdkbGNpMTNaV0pvYjI5ckxXTmhNQjRYRFRJME1EY3lNREEyTXpneQpPRm9YRFRJMU1EY3lNREEyTXpneU9Gb3dIekVkTUJzR0ExVUVBd3dVWTJWeWRDMXRZVzVoWjJWeUxYZGxZbWh2CmIyc3dnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFETTMzcmtBblVTOURhMlYveGkKa3d3Mm9BNE5TY3podWNLcHUyOU9CYkFzUTZQTjFmYnh5V0tZb1RNS0lQSmYraGg0aHFNaDV3TVk4VXZrT0NkeQpKVThLWFRIRndYRis3VDcvcHBsWlFnVndYbU5YMmZ1dXFHVzUwaldDYUV5M1BMYVA2OCtVYjBUS1hqVDV6bVp1CkozSEFGNGhtTXRWZFNra2NtT0FNVHJPMFdudjk1OHB0bW1tT2YyemZKMnBGRHNFRFJMUWxRdDRqUWJWM09USkQKM2U3cHdnUjhjOXEzeDV0aGhpZ1NHUW1hQWdJS1ZZWXpWOUtKc0k1cmtQMDhMNjh1TllGZlY1ZkdPRS9oamY5dwpQdFI2UWFNeGp5UVZYTEtLb0NWMzkwWjNXaWZBdXFpZUhxbERjR2cyN3lCWmw5TjFHTjBIdzZyZkVDQ1kwNTdZCi82T0JBZ01CQUFFd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFIaC9qcmdicXpPWXNZZU1PSnhRbXVqNit2SXcKUE50ZEJMSlpLTE1QUjREUDl2T0puYmI0Zms2Z2dQUWFTYXA4OXVVU2RwV1RpNEFKZGlYS1BxaHFKdmJnOUM4VQo3QW9DQUNsWkM0djcrMVdGczBLcmlpWC8xajhXSzBpaGV3QmpFd1N5QWtJbTZBbjV4Wkd0K1BPK0E2bmxLSzlWClQwYnlIRkthdi81QzJwQXQ4SXdOOHFJTWU0aEFuZ0JmbmNEMnJnejd6TWpNV1plVFI4MzNMOC9IYWsvZi9pSEEKQjVOTnpQNU9vUHNaZUtGeTlXVnlYQVBjQi96YlNxSFdUL01OYllzRmVDTjhac3ByQ2pHVCtxVlh1ZWlEYW5BRQppb1UwU3VLZ3VaMTJzQlNCYnl4QWxQUWhJQkM0eEEwcndMMGtlOE9yQWlsYnY2c0RkMDJxMHJpUnNOYz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=","tls.key":"LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2QUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktZd2dnU2lBZ0VBQW9JQkFRRE0zM3JrQW5VUzlEYTIKVi94aWt3dzJvQTROU2N6aHVjS3B1MjlPQmJBc1E2UE4xZmJ4eVdLWW9UTUtJUEpmK2hoNGhxTWg1d01ZOFV2awpPQ2R5SlU4S1hUSEZ3WEYrN1Q3L3BwbFpRZ1Z3WG1OWDJmdXVxR1c1MGpXQ2FFeTNQTGFQNjgrVWIwVEtYalQ1CnptWnVKM0hBRjRobU10VmRTa2tjbU9BTVRyTzBXbnY5NThwdG1tbU9mMnpmSjJwRkRzRURSTFFsUXQ0alFiVjMKT1RKRDNlN3B3Z1I4YzlxM3g1dGhoaWdTR1FtYUFnSUtWWVl6VjlLSnNJNXJrUDA4TDY4dU5ZRmZWNWZHT0UvaApqZjl3UHRSNlFhTXhqeVFWWExLS29DVjM5MFozV2lmQXVxaWVIcWxEY0dnMjd5QlpsOU4xR04wSHc2cmZFQ0NZCjA1N1kvNk9CQWdNQkFBRUNnZ0VBQ1UwMk42Ynk2TTdrc3dld29rc1oyVnNQK0VON0JWNlpPM3FTbGFERmZHVC8KeVdjbkJKaEhuVFZvYTFQT25WUHVDMzdWWmtNbVRWb2JQM3ZiTXFBR0JDcnlDUS84MXEzdjE4eVpGc2ZjRmx0Ngp1RERoNys2ZVc3N3pCZjQxU1haOHRYRVg1aDNkS2pEM3g4VzZ1ZEtacEFhTmYxSmNoSlZNVjN1TFpKT29MZzUrCnhFc3hTb0J6NE1BcHpQS2NlVEd1Q1VXYVFzd1lLZm9INnVETGIyM3dBWVdDQTN5OFpEZS9mKzEzVkI1c0hSQi8KbWlnZjBBZllPQUVMZzZWWGpjOHRwelB4U3QyR25lNGREN2E3Mm9CNFJybW9iV2tkeXFYV21PeGdKTURJVURPagp1cCtEM1hybUkrcm5MWlY3UkdBeVJsNmRTdml3eGhPc0lIUGhFaVF0YVFLQmdRRDZwQTZJWDFVZkN1T2Rzam9sClZGS2lFMnFud2tYdE1iZ3F1NzFvTWduMGhWT1NlKzI1NEN6K3hPOEdsVkJ1bGtsbWJ3N3daaVRQeVA3MjZRVmIKUGk5TFovd3pxaVpZRkF3cGMyMnYrcjc2T1FqRHM5OEo2RU1JNW55MzNPSTdlcUE1L3B0Q2o4R3dORUo2ZXdpeQpVa1J6SzVWTmo0VEVpOFpLYXZiNTBFUmZCUUtCZ1FEUlFPYllLL21oL3NQNzBaQnhleEZHMFpraHBXdVdObVJ0Ckw5UTFGRDk4VDJUNmRKdWwwSlI4Q0M1bksxUTR6ajE1M2ZvbEZNU0U1U1o0V1Rld0FNY1gwSlU3dmlmZlZ1bFkKQzNYcERsQ0NSQ2N0OHlxT21tWFRqNm9Ha1JDOFJBTFpwWE9nL2J4S1ZnYTdKVjNSU0l0SldsZnRITXA0MGxNOQpkRjRyZHFvRFRRS0JnQm1SN3lHZWlES1lpOHdreUtYU1NuUGFnMEVHSXRnbUFHSHJzVkVWK2NvR2FCWkRxbWNTCkpjVUFGbHFYbFJNVEpmM2JTcXpmM3RXTDdlY0dzdE15THVVRWdNaE1qWWppMHJMUDRkcllPKytQTGdPNU1BSDAKdmhJRVlham9VZlE3ZUdreVBtaTEvYzZhSmtZVWt6aU9DQW12NHBWOUZOQndhaFJoZ1R6UE1JcDVBb0dBT2lJYwp2OHVmdzRpQ3JBL3hZQVYvckR3SW5kZFdCMW8vRmpKbWN3U1lDcElJREtpZW9UZE1PUlVReHlxN2NEaWp6WnFFCnB3Nlk5ZzZ2WEZuMDVabWh0aFVGa0o1b2QxeXU0UDMyR1BRWUc4aVJWZXVyVkFqQzV6NlBUdG00VzRWTmdXZTgKc3VvckNEL1VDT1A5cDJuUEFHYnY3SGpHSzBETFRWUnA0UXRMZWpVQ2dZQkU4YS82VXBDck1aNm5NOWphcElRZgprejVjWWJHSFFDZmw4MkF6elNUaEIwb3p6ODBWY1VJdW44d3pYRkRqOXhJZThXUFlTWEJwSzdQazhSRUxMUmJEClYvNWlwNnpCMzNiSC9Vd2p4MFFnKytxMDA1aHdBcTF6WHZuVDkyU0VGeEFBUkluM3NVdkMvKzNzU2lCeEIzVFcKU3k0aHNBcUZ4ZXN2eGdvcFFDSGFNQT09Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K"},"kind":"Secret","metadata":{"annotations":{"cert-manager.io/allow-direct-injection":"true"},"name":"cert-manager-webhook-ca","namespace":"cert-manager"},"type":"Opaque"}
    cert-manager.io/allow-direct-injection: "true"
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURKVENDQWcyZ0F3SUJBZ0lVUGYvTW14MFRGU21KenZwc3BsZ3dhMk5ERVkwd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0lqRWdNQjRHQTFVRUF3d1hZMlZ5ZEMxdFlXNWhaMlZ5TFhkbFltaHZiMnN0WTJFd0hoY05NalF3TnpJdwpNRFl6TnpVNVdoY05NalV3TnpJd01EWXpOelU1V2pBaU1TQXdIZ1lEVlFRRERCZGpaWEowTFcxaGJtRm5aWEl0CmQyVmlhRzl2YXkxallUQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUltaThhNmsKLzByM2dTSnNCRnZHRnVGNC9JZGZuVk9yRDJFaVZjcTN3a2JHTkJwWTN4UjVCTERnNE13YjVaZUl1YUdBeTkxZAphYjNMdVhJTVhDdWlMUGdsVHJVUnkxcGdtUm9HbDN6MEd2RnA0ekRCNzN0R3g0SHpKU2FleHEycm8zV3dOdHlwCkQ4Znhzejd0ZEYzQVlmM2sxYitsNjF4M3FHT3hiL0tmMi9tdE4wTW9SOWVMc0JaeGU2YWpzVG1zbFFmZ1hnaFMKNXI1US9BSGUzb1Z0TngyTTZqc1ZudW1JNEhTd2dkTFI2akoxTjJNTXh4VXhHdy9uNlJFU3U0QUwwbi96a2dySQpMNVUweXZtdm9iVmMydklSL1B6VTk2c1UxM0ZKazhqNmV5OGZkM0Y1TmRwN3E0bkdLVDByTkVtSlZQWjRHOE1JCk1GZXVvdWdnUU56cXg5MENBd0VBQWFOVE1GRXdIUVlEVlIwT0JCWUVGTFpVZ1FIbmdGeGhDZWY5YjhzUHp3cVQKamlycU1COEdBMVVkSXdRWU1CYUFGTFpVZ1FIbmdGeGhDZWY5YjhzUHp3cVRqaXJxTUE4R0ExVWRFd0VCL3dRRgpNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEZWYwRHg0SU56WWRzVVNKRG9MYW9kUmF6clFVYlNLCjBNak52ZE9lTlhQVG12WEZSc2FYMzRzOXVhNDB0OStGS3VNSlBIQnBwUzBLZmZ2NGVWdHpEWlkzTHhVU21vMmgKZkdPNkJTdE1WbVBycG5jWE9mNzlmTDhlZkkwd1JNdDRnbHQvUjBGamhYRDhlRGJsQzhOU0ZqUmlSdTJXZ1ZGRQpBQ1hrUVUvVkt1TmtXK01pOXU0ei96a1lvYmw2VmF2SmVtS1RiTzZ3TSs2b3BkdG0xMFFyZmNwZDgwbW9mMkJKClRmbU0rdGJ4RmExWkdPSDVUUGVZL1JERWxMUlBOcDh0blZqdW9qVmdTaTcrOTc4aUVxZlpOL3dSVWxSRFhDWlQKZElpUkI2MGMxbzEyTm0rYUNhRUtWYmRVL3dOSzdQbjVSdU9jN3JNK1NHZjNoMGhMcnlKMm1vdz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJBQ0ZEYThQTXAyOXNuRGRVd2hJYThTZG5sV21xM1JNQTBHQ1NxR1NJYjNEUUVCQ3dVQU1DSXgKSURBZUJnTlZCQU1NRjJObGNuUXRiV0Z1WVdkbGNpMTNaV0pvYjI5ckxXTmhNQjRYRFRJME1EY3lNREEyTXpneQpPRm9YRFRJMU1EY3lNREEyTXpneU9Gb3dIekVkTUJzR0ExVUVBd3dVWTJWeWRDMXRZVzVoWjJWeUxYZGxZbWh2CmIyc3dnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFETTMzcmtBblVTOURhMlYveGkKa3d3Mm9BNE5TY3podWNLcHUyOU9CYkFzUTZQTjFmYnh5V0tZb1RNS0lQSmYraGg0aHFNaDV3TVk4VXZrT0NkeQpKVThLWFRIRndYRis3VDcvcHBsWlFnVndYbU5YMmZ1dXFHVzUwaldDYUV5M1BMYVA2OCtVYjBUS1hqVDV6bVp1CkozSEFGNGhtTXRWZFNra2NtT0FNVHJPMFdudjk1OHB0bW1tT2YyemZKMnBGRHNFRFJMUWxRdDRqUWJWM09USkQKM2U3cHdnUjhjOXEzeDV0aGhpZ1NHUW1hQWdJS1ZZWXpWOUtKc0k1cmtQMDhMNjh1TllGZlY1ZkdPRS9oamY5dwpQdFI2UWFNeGp5UVZYTEtLb0NWMzkwWjNXaWZBdXFpZUhxbERjR2cyN3lCWmw5TjFHTjBIdzZyZkVDQ1kwNTdZCi82T0JBZ01CQUFFd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFIaC9qcmdicXpPWXNZZU1PSnhRbXVqNit2SXcKUE50ZEJMSlpLTE1QUjREUDl2T0puYmI0Zms2Z2dQUWFTYXA4OXVVU2RwV1RpNEFKZGlYS1BxaHFKdmJnOUM4VQo3QW9DQUNsWkM0djcrMVdGczBLcmlpWC8xajhXSzBpaGV3QmpFd1N5QWtJbTZBbjV4Wkd0K1BPK0E2bmxLSzlWClQwYnlIRkthdi81QzJwQXQ4SXdOOHFJTWU0aEFuZ0JmbmNEMnJnejd6TWpNV1plVFI4MzNMOC9IYWsvZi9pSEEKQjVOTnpQNU9vUHNaZUtGeTlXVnlYQVBjQi96YlNxSFdUL01OYllzRmVDTjhac3ByQ2pHVCtxVlh1ZWlEYW5BRQppb1UwU3VLZ3VaMTJzQlNCYnl4QWxQUWhJQkM0eEEwcndMMGtlOE9yQWlsYnY2c0RkMDJxMHJpUnNOYz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2QUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktZd2dnU2lBZ0VBQW9JQkFRRE0zM3JrQW5VUzlEYTIKVi94aWt3dzJvQTROU2N6aHVjS3B1MjlPQmJBc1E2UE4xZmJ4eVdLWW9UTUtJUEpmK2hoNGhxTWg1d01ZOFV2awpPQ2R5SlU4S1hUSEZ3WEYrN1Q3L3BwbFpRZ1Z3WG1OWDJmdXVxR1c1MGpXQ2FFeTNQTGFQNjgrVWIwVEtYalQ1CnptWnVKM0hBRjRobU10VmRTa2tjbU9BTVRyTzBXbnY5NThwdG1tbU9mMnpmSjJwRkRzRURSTFFsUXQ0alFiVjMKT1RKRDNlN3B3Z1I4YzlxM3g1dGhoaWdTR1FtYUFnSUtWWVl6VjlLSnNJNXJrUDA4TDY4dU5ZRmZWNWZHT0UvaApqZjl3UHRSNlFhTXhqeVFWWExLS29DVjM5MFozV2lmQXVxaWVIcWxEY0dnMjd5QlpsOU4xR04wSHc2cmZFQ0NZCjA1N1kvNk9CQWdNQkFBRUNnZ0VBQ1UwMk42Ynk2TTdrc3dld29rc1oyVnNQK0VON0JWNlpPM3FTbGFERmZHVC8KeVdjbkJKaEhuVFZvYTFQT25WUHVDMzdWWmtNbVRWb2JQM3ZiTXFBR0JDcnlDUS84MXEzdjE4eVpGc2ZjRmx0Ngp1RERoNys2ZVc3N3pCZjQxU1haOHRYRVg1aDNkS2pEM3g4VzZ1ZEtacEFhTmYxSmNoSlZNVjN1TFpKT29MZzUrCnhFc3hTb0J6NE1BcHpQS2NlVEd1Q1VXYVFzd1lLZm9INnVETGIyM3dBWVdDQTN5OFpEZS9mKzEzVkI1c0hSQi8KbWlnZjBBZllPQUVMZzZWWGpjOHRwelB4U3QyR25lNGREN2E3Mm9CNFJybW9iV2tkeXFYV21PeGdKTURJVURPagp1cCtEM1hybUkrcm5MWlY3UkdBeVJsNmRTdml3eGhPc0lIUGhFaVF0YVFLQmdRRDZwQTZJWDFVZkN1T2Rzam9sClZGS2lFMnFud2tYdE1iZ3F1NzFvTWduMGhWT1NlKzI1NEN6K3hPOEdsVkJ1bGtsbWJ3N3daaVRQeVA3MjZRVmIKUGk5TFovd3pxaVpZRkF3cGMyMnYrcjc2T1FqRHM5OEo2RU1JNW55MzNPSTdlcUE1L3B0Q2o4R3dORUo2ZXdpeQpVa1J6SzVWTmo0VEVpOFpLYXZiNTBFUmZCUUtCZ1FEUlFPYllLL21oL3NQNzBaQnhleEZHMFpraHBXdVdObVJ0Ckw5UTFGRDk4VDJUNmRKdWwwSlI4Q0M1bksxUTR6ajE1M2ZvbEZNU0U1U1o0V1Rld0FNY1gwSlU3dmlmZlZ1bFkKQzNYcERsQ0NSQ2N0OHlxT21tWFRqNm9Ha1JDOFJBTFpwWE9nL2J4S1ZnYTdKVjNSU0l0SldsZnRITXA0MGxNOQpkRjRyZHFvRFRRS0JnQm1SN3lHZWlES1lpOHdreUtYU1NuUGFnMEVHSXRnbUFHSHJzVkVWK2NvR2FCWkRxbWNTCkpjVUFGbHFYbFJNVEpmM2JTcXpmM3RXTDdlY0dzdE15THVVRWdNaE1qWWppMHJMUDRkcllPKytQTGdPNU1BSDAKdmhJRVlham9VZlE3ZUdreVBtaTEvYzZhSmtZVWt6aU9DQW12NHBWOUZOQndhaFJoZ1R6UE1JcDVBb0dBT2lJYwp2OHVmdzRpQ3JBL3hZQVYvckR3SW5kZFdCMW8vRmpKbWN3U1lDcElJREtpZW9UZE1PUlVReHlxN2NEaWp6WnFFCnB3Nlk5ZzZ2WEZuMDVabWh0aFVGa0o1b2QxeXU0UDMyR1BRWUc4aVJWZXVyVkFqQzV6NlBUdG00VzRWTmdXZTgKc3VvckNEL1VDT1A5cDJuUEFHYnY3SGpHSzBETFRWUnA0UXRMZWpVQ2dZQkU4YS82VXBDck1aNm5NOWphcElRZgprejVjWWJHSFFDZmw4MkF6elNUaEIwb3p6ODBWY1VJdW44d3pYRkRqOXhJZThXUFlTWEJwSzdQazhSRUxMUmJEClYvNWlwNnpCMzNiSC9Vd2p4MFFnKytxMDA1aHdBcTF6WHZuVDkyU0VGeEFBUkluM3NVdkMvKzNzU2lCeEIzVFcKU3k0aHNBcUZ4ZXN2eGdvcFFDSGFNQT09Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K
type: Opaque
YAML


}


resource "kubectl_manifest" "cert-manager-webhook-mutating" {
  yaml_body = <<YAML
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  annotations:
    cert-manager.io/inject-ca-from-secret: cert-manager/cert-manager-webhook-ca
    meta.helm.sh/release-name: cert-manager
    meta.helm.sh/release-namespace: cert-manager
  name: cert-manager-webhook-mutating
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJ3VENDQVVlZ0F3SUJBZ0lRVk5uSTNCaS83WVVxRHhJS0wrUlB5akFLQmdncWhrak9QUVFEQXpBaU1TQXcKSGdZRFZRUURFeGRqWlhKMExXMWhibUZuWlhJdGQyVmlhRzl2YXkxallUQWVGdzB5TkRBM01qQXdOalV3TlRaYQpGdzB5TlRBM01qQXdOalV3TlRaYU1DSXhJREFlQmdOVkJBTVRGMk5sY25RdGJXRnVZV2RsY2kxM1pXSm9iMjlyCkxXTmhNSFl3RUFZSEtvWkl6ajBDQVFZRks0RUVBQ0lEWWdBRWUwdmNHajNhZDUwYm9UMjlSb0x1eUdFeko5OUIKT3l2SzRMdmQ1eG4yT3ZtdzVXcjhwalgzcnNXcWFNN3NNdWhZUUdicndxTDlLaTB5SE1HT3N0V3hRUGJFSTMrQwpiRkpvbytBNnpNUHg1akhXa3EreDE0OHg1RVpFVEVBbDk0WUlvMEl3UURBT0JnTlZIUThCQWY4RUJBTUNBcVF3CkR3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVUd0YWE1cHkwREozc1VTT1p1cUxqODYwRGxPOHcKQ2dZSUtvWkl6ajBFQXdNRGFBQXdaUUl4QU80Z0NXZXFSZmpNOGFTRGYzOFM1SDZYYnVSaEJoQ1N1TkdxaWlXcApzUlRtaFlmR1duc1U5TmlMazI5bUtZZ1krd0l3SGduR3l5QmhRN08vTzVvdTk4S2xDdUZQR0FlOTVtUEdsOVgwCi80cXdINUhUOXRuMS9Ud3JIQ2VnY2N1RXdlbGYKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    service:
      name: cert-manager-webhook
      namespace: cert-manager
      path: /mutate
      port: 443
  failurePolicy: Fail
  matchPolicy: Equivalent
  name: webhook.cert-manager.io
  namespaceSelector: {}
  objectSelector: {}
  reinvocationPolicy: Never
  rules:
  - apiGroups:
    - cert-manager.io
    apiVersions:
    - v1
    operations:
    - CREATE
    resources:
    - certificaterequests
    scope: '*'
  sideEffects: None
  timeoutSeconds: 30
YAML


}

resource "kubectl_manifest" "docker_registry_secret" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: defectdojoregistrykey
  namespace: default
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOnsidXNlcm5hbWUiOiJ0cmF5M3JkIiwicGFzc3dvcmQiOiJ+MTQxTzkwbGQ5NzQxTm9ydGhlcm4iLCJhdXRoIjoiWVdSb2JHRnRjeTVwYldGeVlXNXplU0J3WlhKaGRHOXlZWFJwYjI0PT0ifX19
YAML
}


resource "kubectl_manifest" "cert-manager-webhook-validating" {
  yaml_body = <<YAML
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  annotations:
    cert-manager.io/inject-ca-from-secret: cert-manager/cert-manager-webhook-ca
    meta.helm.sh/release-name: cert-manager
    meta.helm.sh/release-namespace: cert-manager
  name: cert-manager-webhook-validating
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJ3VENDQVVlZ0F3SUJBZ0lRVk5uSTNCaS83WVVxRHhJS0wrUlB5akFLQmdncWhrak9QUVFEQXpBaU1TQXcKSGdZRFZRUURFeGRqWlhKMExXMWhibUZuWlhJdGQyVmlhRzl2YXkxallUQWVGdzB5TkRBM01qQXdOalV3TlRaYQpGdzB5TlRBM01qQXdOalV3TlRaYU1DSXhJREFlQmdOVkJBTVRGMk5sY25RdGJXRnVZV2RsY2kxM1pXSm9iMjlyCkxXTmhNSFl3RUFZSEtvWkl6ajBDQVFZRks0RUVBQ0lEWWdBRWUwdmNHajNhZDUwYm9UMjlSb0x1eUdFeko5OUIKT3l2SzRMdmQ1eG4yT3ZtdzVXcjhwalgzcnNXcWFNN3NNdWhZUUdicndxTDlLaTB5SE1HT3N0V3hRUGJFSTMrQwpiRkpvbytBNnpNUHg1akhXa3EreDE0OHg1RVpFVEVBbDk0WUlvMEl3UURBT0JnTlZIUThCQWY4RUJBTUNBcVF3CkR3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVUd0YWE1cHkwREozc1VTT1p1cUxqODYwRGxPOHcKQ2dZSUtvWkl6ajBFQXdNRGFBQXdaUUl4QU80Z0NXZXFSZmpNOGFTRGYzOFM1SDZYYnVSaEJoQ1N1TkdxaWlXcApzUlRtaFlmR1duc1U5TmlMazI5bUtZZ1krd0l3SGduR3l5QmhRN08vTzVvdTk4S2xDdUZQR0FlOTVtUEdsOVgwCi80cXdINUhUOXRuMS9Ud3JIQ2VnY2N1RXdlbGYKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    service:
      name: cert-manager-webhook
      namespace: cert-manager
      path: /validate
      port: 443
  failurePolicy: Fail
  matchPolicy: Equivalent
  name: webhook.cert-manager.io
  namespaceSelector:
    matchExpressions:
    - key: cert-manager.io/disable-validation
      operator: NotIn
      values:
      - "true"
  objectSelector: {}
  rules:
  - apiGroups:
    - cert-manager.io
    - acme.cert-manager.io
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*/*'
    scope: '*'
  sideEffects: None
  timeoutSeconds: 30
YAML

depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "TLSOption" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: default
  namespace: traefik
spec:
  minVersion: VersionTLS12

YAML

depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "Middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: https-redirect
  namespace: defectdojo
spec:
  redirectScheme:
    scheme: https
    permanent: true
YAML

depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "IngressRouteSecure" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: defectdojo-app-secure
  namespace: defectdojo
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`defectdojo.secops-ba.win`)
      kind: Rule
      middlewares:
        - name: secure-headers
          namespace: defectdojo
      services:
        - name: defectdojo-django
          namespace: defectdojo
          port: http
  tls:
    secretName: defectdojo-tls
YAML

depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "IngressRoute" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: defectdojo-app
  namespace: defectdojo
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`defectdojo.secops-ba.win`)
      kind: Rule
      middlewares:
        - name: https-redirect
          namespace: defectdojo
        - name: secure-headers
          namespace: defectdojo
      services:
        - name: defectdojo-django
          namespace: defectdojo
          port: http
YAML

depends_on = [helm_release.traefik]
}



resource "kubectl_manifest" "secure_headers" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: secure-headers
  namespace: defectdojo
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-For: "{clientIP}"
      X-Forwarded-Proto: "https"
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    stsPreload: true
YAML

depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "test_ipallowlist" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: MiddlewareTCP
metadata:
  name: test-ipallowlist
  namespace: default
spec:
  ipAllowList:
    sourceRange:
      - 127.0.0.1/32
      - 100.36.68.167/32
YAML

depends_on = [helm_release.traefik]
}

resource "kubectl_manifest" "test_ipallowlist2" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: test-ipallowlist
  namespace: default
spec:
  ipAllowList:
    sourceRange:
      - 127.0.0.1/32
      - 100.36.68.167/32
YAML

depends_on = [helm_release.traefik]
}



#KMS key to encrypt EKS EBS
module "ebs_kms_key" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "2.2.0"
  description = "Customer managed key to encrypt EKS managed node group volumes"
  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]
  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
  ]
  # Aliases
  aliases = ["eks/${var.eks_cluster_name}/ebs"]
}

data "tls_certificate" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

#EKS cluster
module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types       = var.eks_cluster_log_types

#  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  custom_oidc_thumbprints   = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  cluster_security_group_additional_rules = {
    eks_sg = {
      description = "All from VPC"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks_kms_key.arn
      resources        = ["secrets"]
    }
  ]

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.env}-ebs-csi-controller"
      resolve_conflicts        = "PRESERVE"
    }
  }

  eks_managed_node_groups = {

    eks_managed_node1 = {
      min_size              = var.eks_cluster_min_size
      max_size              = var.eks_cluster_max_size
      desired_size          = var.eks_cluster_des_size
      ami_type              = var.eks_cluster_ami_type
      instance_types        = [var.eks_cluster_instance_type]
      capacity_type         = var.eks_cluster_capacity
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 80
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/eks/${var.eks_cluster_name}/ebs"
            delete_on_termination = true
          }
        }
      }
      iam_role_additional_policies = [
        "arn:aws:iam::aws:policy/CloudWatchFullAccessV2",
      ]

      tags = {
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"                 = "TRUE"
      }

      update_config = {
        max_unavailable_percentage = var.eks_max_unavailable_percentage
      }

    }

  }

  aws_auth_roles = var.eks_map_roles

}

