allprojects {
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.layout.buildDirectory = file("../build")
subprojects {
  project.layout.buildDirectory = rootProject.layout.buildDirectory.file(project.name).get().asFile
}

subprojects {
  project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
  delete(rootProject.layout.buildDirectory)
} 