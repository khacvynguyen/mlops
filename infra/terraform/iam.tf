resource "google_project_iam_member" "jenkins_artifactregistry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:jenkins-ci@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "jenkins_cloudbuild_viewer" {
  project = var.cloudbuild_logs_project_id
  role    = "roles/cloudbuild.builds.viewer"
  member  = "serviceAccount:jenkins-ci@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "jenkins_logs_object_viewer" {
  project = var.cloudbuild_logs_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:jenkins-ci@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "jenkins_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:jenkins-ci@${var.project_id}.iam.gserviceaccount.com"
}