allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

val rootProjectPath = rootProject.projectDir.toPath().toAbsolutePath().normalize()

subprojects {
    val subprojectPath = project.projectDir.toPath().toAbsolutePath().normalize()

    // Keep external plugin modules (e.g. Pub cache on another drive) on their default build dirs.
    if (subprojectPath.startsWith(rootProjectPath)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
