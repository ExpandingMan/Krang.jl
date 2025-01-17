export render
abstract type AbstractScheme end

function render(camera::AbstractCamera, scene::Scene)  

    mapreduce(
        mesh -> mesh.material.(camera.screen.pixels, Ref(mesh.geometry)),
        +,
        scene
    )
end
