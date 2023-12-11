from minimum import OptimizerOptuna


def parabola(x):
    return (x ** 2).sum()


if __name__ == '__main__':
    opt = OptimizerOptuna()
    opt.add_parameter('x', .5, -1, 1)
    opt.add_parameter('y', .5, -1, 1)
    opt.add_parameter('z', .5, -1, 1)
    opt.add_objective('parabola', parabola)

    study = opt.main()

    print(opt.history.data)
