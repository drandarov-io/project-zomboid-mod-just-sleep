//----------------------------------------------------------------------------------------------------------------------
// Project Setup
//----------------------------------------------------------------------------------------------------------------------

plugins {
    java
}

val zomboidjar: String by project
val zomboidjarsources: String by project
val zomboidlua: String by project
val zomboidmedia: String by project

dependencies {
    implementation(files(zomboidjar))
    implementation(files(zomboidjarsources))
    implementation(files(zomboidlua))
    implementation(files(zomboidmedia))
}

sourceSets.create("media") {
    java.srcDir("media")

    compileClasspath += sourceSets.main.get().compileClasspath
}


//----------------------------------------------------------------------------------------------------------------------
// Tasks
//----------------------------------------------------------------------------------------------------------------------

val projectName = if (project.hasProperty("betaBuild")) "${project.name}-beta" else project.name

val buildPath = "$buildDir/workshop/${projectName}"
val modPath = "$buildPath/Contents/mods/${projectName}"

val localPath = "${System.getProperties()["user.home"]}/Zomboid/Workshop"
val localModPath = "$localPath/${projectName}"

val buildWorkshop by tasks.registering {

    group = "build"
    outputs.dir("$buildDir/workshop")

    doLast {
        copy {
            from(if (project.hasProperty("betaBuild")) "workshop/preview_beta.png" else "workshop/preview.png", "workshop/workshop.txt")
            into(buildPath)
            rename("preview_beta.png", "preview.png")
        }

        copy {
            from(if (project.hasProperty("betaBuild")) "workshop/poster_beta.png" else "workshop/poster.png", "workshop/mod.info")
            into(modPath)
            rename("poster_beta.png", "poster.png")
        }
        copy {
            from("media")
            into("$modPath/media")
        }
    }
}

val localDeploy by tasks.registering {

    group = "build"
    outputs.dir("$localPath/${projectName}")

    dependsOn(buildWorkshop)

    doFirst {
        if (project.hasProperty("betaBuild")) {
            File("$modPath/mod.info").writeText(File("$modPath/mod.info").readText().replace("id=${project.name}", "id=$projectName"))
            File("$modPath/mod.info").writeText(File("$modPath/mod.info").readText().replaceFirst("(name=.*)".toRegex(), "$1 [Beta]"))
        }
    }

    doLast {
        copy {
            from(buildWorkshop.get().outputs.files)
            into(localPath)
        }
    }
}


val localUndeploy by tasks.registering {
    val localPath = "${System.getProperties()["user.home"]}/Zomboid/Workshop"

    group = "build"

    doLast {
        delete(localDeploy.get().outputs.files)
    }
}
