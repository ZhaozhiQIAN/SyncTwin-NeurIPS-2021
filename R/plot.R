library(ggplot2)
library(reshape2)
library(latex2exp)


dat = read.csv('ICLR-hyper-parameter-sensitivity.csv', stringsAsFactors = FALSE)

head(dat)
names(dat)[1] = 'param'
dat$mae_sd = NULL

dat_m = melt(dat, id.vars = c('param', 'val'))

param.labs <- unname(TeX(c("$\\tau$", "H", "$\\lambda_p$")))


param.labs <- c('tau', 'H', 'lambda_p')
names(param.labs) <- c("tau", "H", "lambda_p")


ggplot(data = dat_m) +
    facet_wrap('param', ncol=3, scale='free_x', labeller = labeller(param = param.labs)) +
    geom_line(aes(x=val, y=value, color=variable), size=1.1) + 
    geom_point(aes(x=val, y=value, color=variable), size=2) +
    scale_y_continuous(trans='log2') +
    scale_color_discrete(labels = c('MAE on ITE', 'Validation Loss')) +
    guides(color=guide_legend(title=NULL, override.aes=list('color'))) + 
    xlab('') +
    ylab('') +
    theme_bw() +
    theme(legend.position='top')
    

ggsave(filename='hyper_param.pdf', dpi=300, width=8, height=4, units='in')



# geom_hline(yintercept = 0.1) +
    geom_col(aes(x=sample_size, y=`Type-I Error`, fill=data),
             alpha=0.7, width = 0.8, position=position_dodge2(width=1)) +
    geom_linerange(aes(x=sample_size, ymin = lower, ymax = upper, color=data), 
                   position = position_dodge2(width=0.8) ) +
    scale_fill_brewer(palette="Dark2") + 
    scale_color_brewer(palette="Dark2", guide=FALSE) +
    guides(fill=guide_legend(title=NULL, override.aes=list('fill'))) + 
    xlab('Sample Size') +
    theme_bw() +
    theme(legend.position='top')
    
    

# CPU time ----------------------------------------------------------------

dat = read.csv('ICLR-cpu-time.csv', stringsAsFactors = FALSE)
    
names(dat)[1] = 'N0'


head(dat)

dat$lower = dat$time - dat$sd
dat$upper = dat$time + dat$sd
dat$N0 = factor(dat$N0)
dat$t0 = factor(dat$t0)

ggplot(data = dat) +
    geom_col(aes(x=N0, y=time, fill=t0),
             alpha=0.7, width = 0.8, position=position_dodge2(width=1)) +
    geom_linerange(aes(x=N0, ymin = lower, ymax = upper), 
                   position = position_dodge2(width=0.8), size=2 ) +
    scale_fill_brewer(palette="Dark2") + 
    scale_color_brewer(palette="Dark2", guide=FALSE) +
    xlab('Size of Control Group: N0') +
    ylab('Wall-clock time in seconds') +
    labs(fill=expression(t[0])) +
    theme_bw() +
    theme(legend.position='top')

ggsave(filename='cpu.pdf', dpi=300, width=8, height=4, units='in')


# Matched sample ----------------------------------------------------------


dat = read.csv('ICLR-matched.csv', stringsAsFactors = FALSE)


names(dat)[1] = 'method'


head(dat)

dat$lower = dat$nm - 2 * dat$sd
dat$upper = dat$nm + 2 *dat$sd
dat$N0 = factor(dat$N0)
dat$t0 = factor(dat$t0)



param.labs <- c('N0 = 200', 'N0 = 1000')
names(param.labs) <- c('200', '1000')


ggplot(data = dat) +
    facet_wrap('N0', ncol=2, labeller = labeller(N0 = param.labs)) +
    geom_col(aes(x=t0, y=nm, fill=method),
             alpha=0.7, width = 0.8, position=position_dodge2(width=1)) +
    geom_linerange(aes(x=t0, ymin = lower, ymax = upper), 
                   position = position_dodge2(width=0.8), size=2 ) +
    scale_fill_brewer(palette="Dark2") + 
    scale_color_brewer(palette="Dark2", guide=FALSE) +
    xlab('Pre-treatment period: t0') +
    ylab('Number of matched units') +
    labs(fill='Method') +
    theme_bw() +
    theme(legend.position='top')

ggsave(filename='match.pdf', dpi=300, width=7, height=3, units='in')
