import { Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip } from 'recharts';
import styles from '../../styles/Dashboard.module.css';

const COLORS = ['#2563EB', '#10B981', '#F59E0B', '#EF4444'];
const RADIAN = Math.PI / 180;

const renderCustomizedLabel = ({ cx, cy, midAngle, innerRadius, outerRadius, percent }) => {
    const radius = innerRadius + (outerRadius - innerRadius) * 0.5;
    const x = cx + radius * Math.cos(-midAngle * RADIAN);
    const y = cy + radius * Math.sin(-midAngle * RADIAN);

    return (
        <text x={x} y={y} fill="white" textAnchor="middle" dominantBaseline="central" fontSize={11} fontWeight="600">
            {`${(percent * 100).toFixed(0)}%`}
        </text>
    );
};

const DonutChartCard = ({ title, subtitle, data }) => (
    <div className={styles.chartCard}>
        <h3 className={styles.cardTitle}>{title}</h3>
        <span className={styles.chartSub}>{subtitle}</span>
        <ResponsiveContainer width="100%" height={250}>
            <PieChart>
                <Pie
                    data={data}
                    cx="50%"
                    cy="45%"
                    innerRadius={45}
                    outerRadius={75}
                    paddingAngle={5}
                    dataKey="value"
                    labelLine={false}
                    label={renderCustomizedLabel}
                >
                    {data.map((entry, index) => (
                        <Cell key={`${entry.name}-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                </Pie>
                <Tooltip />
                <Legend verticalAlign="bottom" height={36} />
            </PieChart>
        </ResponsiveContainer>
    </div>
);

const DistributionCharts = ({ categoryData, roleData }) => (
    <div className={styles.chartsGrid}>
        <DonutChartCard
            title="Waste Type Distribution"
            subtitle="Breakdown of collected e-waste categories"
            data={categoryData}
        />

        {roleData.length > 0 && (
            <DonutChartCard
                title="System User Distribution"
                subtitle="Breakdown of internal accounts by role"
                data={roleData}
            />
        )}
    </div>
);

export default DistributionCharts;
