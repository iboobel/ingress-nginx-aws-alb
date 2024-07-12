resource "helm_release" "flux" {
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  name             = "flux2"
  create_namespace = true
  version          = "2.12.2"
  depends_on       = [module.eks]
}

resource "kubernetes_manifest" "gitrepository_flux_system_flux_system" {
  manifest = {
    "apiVersion" = "source.toolkit.fluxcd.io/v1beta2"
    "kind"       = "GitRepository"
    "metadata" = {
      "name"      = "main-gitops-repo"
    }
    "spec" = {
      "interval" = "1m0s"
      "ref" = {
        "branch" = "main"
      }
      "secretRef" = {
        "name" = "github-deployment-key"
      }
      "timeout" = "60s"
      "url"     = "ssh://git@github.com/example"
    }
  }
}

resource "kubernetes_manifest" "kustomization_flux_system_flux_system" {
  depends_on = [kubernetes_manifest.gitrepository_flux_system_flux_system]
  manifest = {
    "apiVersion" = "kustomize.toolkit.fluxcd.io/v1beta2"
    "kind"       = "Kustomization"
    "metadata" = {
      "name"      = "develop-cluster"
    }
    "spec" = {
      "force"    = false
      "interval" = "10m0s"
      "path"     = "./path-to-folder-in-repo/develo-cluster"
      "prune"    = false
      "sourceRef" = {
        "kind" = "GitRepository"
        "name" = "main-gitops-repo"
      }
    }
  }
}
