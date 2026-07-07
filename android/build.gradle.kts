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

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. receive_sharing_intent 1.8.x) compile their Java at 1.8
// while their Kotlin targets 17, which Gradle rejects as inconsistent. Force
// Java 17 across every Android subproject so they line up with the app.
subprojects {
    plugins.withId("com.android.library") {
        (extensions.getByName("android") as com.android.build.gradle.BaseExtension)
            .compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
