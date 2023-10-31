@testset "Raytracer Functions" begin

    @testset "Emission radius" begin
        a = 0.99
        met = Kang.Kerr(a)

        @test isnan(emission_radius(met, 10, 1.0, π/2, π/2, true, 2)[1])

        @testset "Case 2" begin
            α = 10.0
            β = 10.0
            θo = π / 4

            ηcase1 = η(met, α, β, θo)
            λcase1 = λ(met, α, θo)
            roots = get_radial_roots(met, ηcase1, λcase1)
            _, _, _, root = roots
            @test sum(Kang._isreal2.(roots)) == 4
            rs = 1.1 * real(root)
            τ1 = Ir(met, true, rs, ηcase1, λcase1)[1]
            @test Kang.emission_radius(met, α, β, τ1, θo)[1] / rs ≈ 1 atol = 1e-5
        end

        @testset "Case 3" begin
            α = 1.0
            β = 1.0
            θo = π / 4

            ηcase3 = η(met, α, β, θo)
            λcase3 = λ(met, α, θo)
            roots = get_radial_roots(met, ηcase3, λcase3)
            @test sum(Kang._isreal2.(roots)) == 2
            rs = 1.1horizon(met)
            τ3 = Ir(met, true, rs, ηcase3, λcase3)[1]
            @test Kang.emission_radius(met, α, β, τ3, θo)[1] / rs ≈ 1 atol = 1e-5
        end
        @testset "Case 4" begin
            α = 0.1
            β = 0.1
            θo = π / 4

            ηcase4 = η(met, α, β, θo)
            λcase4 = λ(met, α, θo)
            roots = get_radial_roots(met, ηcase4, λcase4)
            @test sum(Kang._isreal2.(roots)) == 0
            rs = 1.1horizon(met)
            τ4 = Ir(met, true, rs, ηcase4, λcase4)[1]
            @test Kang.emission_radius(met, α, β, τ4, θo)[1] / rs ≈ 1 atol = 1e-5
        end
    end
    @testset "Emission inclination" begin
        a = 0.99
        met = Kang.Kerr(a)

        @test isnan(emission_radius(met, 10, 1.0, π/2, π/2, true, 2)[1])

        @testset "Ordinary Geodesics" begin
            α = 10.0
            β = 10.0
            θo = π / 4

            @testset "n:$n" for n in 0:2
                @testset "θs:$θs" for θs in [π/5, π/4, π/3, π/2, 2π/3, 3π/4, 4π/5]
                    @testset "isindir:$isindir" for isindir in [true, false]
                        ηcase1 = η(met, α, β, θo)
                        λcase1 = λ(met, α, θo)
                        roots = get_radial_roots(met, ηcase1, λcase1)
                        _, _, _, root = roots
                        τ1, _, _, _, _ = Kang.Gθ(met, α, β, θs, θo, isindir, n)
                        testθs = Kang.emission_inclination(met, α, β, τ1, θo)[1]
                        if !isnan(testθs)
                            @test  testθs/ θs ≈ 1 atol = 1e-5
                        end
                    end
                end
            end
        end

        @testset "Vortical Geodesics" begin
            α = 0.1
            β = 0.1
            θo = π / 4

            @testset "n:$n" for n in 0:2
                @testset "θs:$θs" for θs in [π/5, π/4, π/3, π/2, 2π/3, 3π/4, 4π/5]
                    @testset "isindir:$isindir" for isindir in [true, false]
                        ηcase1 = η(met, α, β, θo)
                        λcase1 = λ(met, α, θo)
                        roots = get_radial_roots(met, ηcase1, λcase1)
                        _, _, _, root = roots
                        τ1, _, _, _, _ = Kang.Gθ(met, α, β, θs, θo, isindir, n)
                        testθs = Kang.emission_inclination(met, α, β, τ1, θo)[1]
                        if !isnan(testθs)
                            @test  testθs/ θs ≈ 1 atol = 1e-5
                        end
                    end
                end
            end
        end
    end
    @testset "Emission Coordinates" begin
        @testset "α:$α, β:$β, isindir:$isindir" for (α, β, isindir) in [(10.0, 10.0, true), (1.0, -1.0, false)]
            θo = π/4
            θs = π/3
            a = 0.99
            met = Kang.Kerr(a)
            ηtemp = η(met, α, β, θo)
            λtemp = λ(met, α, θo)
            a2 = met.spin^2
            Δθ = (1.0 - (ηtemp + λtemp^2) / a2) / 2
            Δθ2 = Δθ^2
            desc = √(Δθ2 + ηtemp / a2)
            up = Δθ + desc
            θturning = acos(√up) * (1 + 1e-10)

            τ = Kang.Gθ(met, α, β, θs, θo, isindir, 0)[1]
            ts, testrs, testθs, ϕs, νr, νθ = Kang.emission_coordinates(met, α, β, θs, θo, isindir, 0)
            testrs2, testθs2, ϕs2, νr2, νθ2 = Kang.emission_coordinates_fast_light(met, α, β, θs, θo, isindir, 0)
            ts3, testrs3, testθs3, ϕs3, νr3, νθ3 = Kang.raytrace(met, α, β, θo, τ)

            testτ = Kang.Ir(met, isindir, testrs, ηtemp, λtemp)[1]
            @testset "Consistency between raytracing methods" begin
                @test testrs/testrs2 ≈ 1.0 atol = 1e-5
                @test testθs/testθs2 ≈ 1.0 atol = 1e-5
                @test ϕs2/ϕs ≈ 1.0 atol = 1e-5
                @test νr == νr2
                @test νθ == νθ2
                @test testrs/testrs3 ≈ 1.0 atol = 1e-5
                @test testθs/testθs3 ≈ 1.0 atol = 1e-5
                @test ϕs/ϕs3 ≈ 1.0 atol = 1e-5
                @test νr == νr3
                @test νθ == νθ3

                @test testθs/θs ≈ 1.0 atol = 1e-5
                @test testτ/τ ≈ 1.0 atol = 1e-5
            end

            fϕ(r, p) = a * (2r - a * λtemp) * inv((r^2 - 2r + a^2) * √(r_potential(met, ηtemp, λtemp, r)))
            probϕ = IntegralProblem(fϕ, testrs, Inf; nout=1)
            solϕ = solve(probϕ, HCubatureJL(); reltol=1e-8, abstol=1e-8)
            Iϕ = solϕ.u

            gϕ(θ, p) = csc(θ)^2 * inv(√(Kang.θ_potential(met, ηtemp, λtemp, θ)))
            probϕs = IntegralProblem(gϕ, θs, π / 2; nout=1)
            solθs = solve(probϕs, HCubatureJL(); reltol=1e-12, abstol=1e-12)
            probϕo = IntegralProblem(gϕ, θo, π / 2; nout=1)
            solθo = solve(probϕo, HCubatureJL(); reltol=1e-12, abstol=1e-12)
            probϕ = IntegralProblem(gϕ, θturning, π / 2; nout=1)
            solθt = solve(probϕ, HCubatureJL(); reltol=1e-12, abstol=1e-12)

            Gϕ = 0
            if isindir
                if sign(cos(θs) * cos(θo)) > 0
                    Gϕ = abs(2solθt.u - (solθo.u + solθs.u))
                else
                    Gϕ = abs(2solθt.u + solθs.u - solθo.u)
                end
            else
                if sign(cos(θs) * cos(θo)) > 0
                    Gϕ = abs(solθo.u - solθs.u)
                else
                    Gϕ = abs(solθo.u + solθs.u)
                end
            end

            @test -(Iϕ + λtemp*Gϕ)/ϕs ≈ 1.0 atol = 1e-3

            ft(r, p) = ((r^2 * (r^2 - 2r + a^2) + 2r * (r^2 + a^2 - a * λtemp)) * inv((r^2 - 2r + a^2) * √(r_potential(met, ηtemp, λtemp, r))))
            probt = IntegralProblem(ft, testrs, 1e6; nout=1)
            solt = solve(probt, HCubatureJL(); reltol=1e-8, abstol=1e-8)
            It = solt.u

            gt(θ, p) = cos(θ)^2 * inv(√(Kang.θ_potential(met, ηtemp, λtemp, θ)))
            probts = IntegralProblem(gt, θs, π / 2; nout=1)
            solθs = solve(probts, HCubatureJL(); reltol=1e-12, abstol=1e-12)
            probto = IntegralProblem(gt, θo, π / 2; nout=1)
            solθo = solve(probto, HCubatureJL(); reltol=1e-12, abstol=1e-12)
            probt = IntegralProblem(gt, θturning, π / 2; nout=1)
            solθt = solve(probt, HCubatureJL(); reltol=1e-12, abstol=1e-12)

            Gt = 0
            if isindir
                if sign(cos(θs) * cos(θo)) > 0
                    Gt = abs(2solθt.u - (solθo.u + solθs.u))
                else
                    Gt = abs(2solθt.u + solθs.u - solθo.u)
                end
            else
                if sign(cos(θs) * cos(θo)) > 0
                    Gt = abs(solθo.u - solθs.u)
                else
                    Gt = abs(solθo.u + solθs.u)
                end
            end

            @test ((It - 1e6 - 2log(1e6)) + a^2*Gt)/ts ≈ 1.0 atol = 1e-3
        end
    end
end